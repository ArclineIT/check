namespace :cdn do
  desc "Refresh config/cdn_ranges.json from the providers' published lists"
  task update: :environment do
    CdnRangesUpdate.new.call.each { |provider, count| puts format("%-12s %5d ranges", provider, count) }
  end
end

namespace :check do
  desc "Check a domain from the terminal: bin/rails 'check:domain[example.com]' (FORMAT=json for JSON)"
  task :domain, [ :domain ] => :environment do |_task, args|
    report = TransparencyCheck.call(DomainName.parse(args[:domain]))
    puts ENV["FORMAT"] == "json" ? JSON.pretty_generate(report.as_json) : report.to_text(color: $stdout.tty?)
    exit 1 unless report.self_hosted?
  rescue DomainName::Invalid => e
    abort e.message
  end
end
