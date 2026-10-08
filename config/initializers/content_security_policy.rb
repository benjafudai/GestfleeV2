# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.script_src      :self, :unsafe_inline, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
    policy.style_src       :self, :unsafe_inline, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com", "https://fonts.googleapis.com"
    policy.font_src        :self, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com", "https://fonts.gstatic.com", :data
    policy.img_src         :self, :data
    policy.connect_src     :self
    # maps.google.com/maps?...&output=embed redirects to www.google.com/maps/embed
    policy.frame_src       "https://maps.google.com", "https://www.google.com"
    policy.object_src      :none
    policy.base_uri        :self
    policy.form_action     :self
    policy.frame_ancestors :self
  end
end
