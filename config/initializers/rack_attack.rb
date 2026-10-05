class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  safelist("allow localhost") do |req|
    ["127.0.0.1", "::1"].include?(req.ip)
  end

  throttle("logins/email", limit: 5, period: 1.minute) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email").to_s.downcase.strip.presence
    end
  end

  # Coarser than the 5/min account-level throttle above on purpose: a strict
  # per-IP limit at the same rate would lock out an entire office/depot behind
  # one NAT after a single mistyped password. The email throttle is what
  # actually protects each account; this one just catches request floods.
  throttle("logins/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  self.throttled_responder = lambda do |request|
    [429,
     { "Content-Type" => "text/plain; charset=utf-8" },
     ["Demasiados intentos de inicio de sesión. Por favor espera un minuto e inténtalo nuevamente.\n"]]
  end
end

Rails.application.config.middleware.use Rack::Attack
