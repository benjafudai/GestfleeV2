# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.script_src      :self, :unsafe_inline, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
    policy.style_src       :self, :unsafe_inline, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
    policy.font_src        :self, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com", :data
    policy.img_src         :self, :data
    policy.connect_src     :self
    policy.frame_src       "https://maps.google.com"
    policy.object_src      :none
    policy.base_uri        :self
    policy.form_action     :self
    policy.frame_ancestors :self
  end
end
