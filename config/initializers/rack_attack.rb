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

  # Every password reset request notifies the GestFlee team (superadmins), so
  # the "forgot password" form is throttled to keep it from being used to
  # flood them. Per email stops hammering one account; per IP stops spraying
  # many different emails from one place.
  throttle("password_resets/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.params.dig("user", "email").to_s.downcase.strip.presence
    end
  end

  throttle("password_resets/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  self.throttled_responder = lambda do |request|
    message =
      if request.env["rack.attack.matched"].to_s.start_with?("password_resets/")
        "Demasiadas solicitudes de recuperación de contraseña. Por favor espera una hora e inténtalo nuevamente.\n"
      else
        "Demasiados intentos de inicio de sesión. Por favor espera un minuto e inténtalo nuevamente.\n"
      end

    [429, { "Content-Type" => "text/plain; charset=utf-8" }, [message]]
  end
end

Rails.application.config.middleware.use Rack::Attack
