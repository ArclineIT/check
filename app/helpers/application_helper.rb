module ApplicationHelper
  ICONS = {
    "contrast" => '<circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 1 0 18Z" fill="currentColor"/>',
    "menu" => '<path d="M4 7h16"/><path d="M4 12h16"/><path d="M4 17h16"/>'
  }.freeze

  def icon(name, size: 20, **options)
    tag.svg(ICONS.fetch(name.to_s).html_safe, xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24",
      width: size, height: size, fill: "none", stroke: "currentColor", "stroke-width": 1.75,
      "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true, focusable: false,
      class: [ "icon", options[:class] ])
  end

  # Maps a finding's status onto the shared badge colours.
  def finding_class(status)
    { "ok" => "ok", "warn" => "warn" }.fetch(status, "pending")
  end
end
