#!/usr/bin/env ruby

require "fileutils"
require "json"
require "optparse"
require "time"

ENV["TZ"] = "Asia/Tokyo"

PROJECT_ROOT = File.expand_path("../../../..", __dir__)
LOG_DIR = File.join(PROJECT_ROOT, "docs", "work-log")
LOG_PATH = File.join(LOG_DIR, "work-log.jsonl")
SUMMARY_PATH = File.join(LOG_DIR, "summary.md")
STATE_DIR = File.join(PROJECT_ROOT, "tmp", "work-log")
ACTIVE_PATH = File.join(STATE_DIR, "active.json")
LOCK_PATH = File.join(STATE_DIR, "work-log.lock")
CATEGORIES = %w[
  planning decision setup implementation testing ui-ux deployment
  documentation submission mixed
].freeze

FileUtils.mkdir_p(LOG_DIR)
FileUtils.mkdir_p(STATE_DIR)

def parse_options(argv, allowed)
  options = {}
  parser = OptionParser.new
  allowed.each do |key|
    next if key == :estimated

    flag = "--#{key.to_s.tr("_", "-")} VALUE"
    parser.on(flag) { |value| options[key] = value }
  end
  parser.on("--estimated") { options[:estimated] = true } if allowed.include?(:estimated)
  parser.parse!(argv)
  options
end

def require_option!(options, key)
  value = options[key]
  abort("Missing --#{key.to_s.tr("_", "-")}") if value.nil? || value.strip.empty?
  value
end

def parse_time(value)
  Time.iso8601(value)
rescue ArgumentError
  abort("Invalid ISO-8601 time: #{value}")
end

def validate_category!(category)
  return category if CATEGORIES.include?(category)

  abort("Invalid category #{category.inspect}. Use: #{CATEGORIES.join(", ")}")
end

def parse_issues(value)
  value.to_s.split(",").map(&:strip).reject(&:empty?).uniq
end

def read_active
  return nil unless File.exist?(ACTIVE_PATH)

  JSON.parse(File.read(ACTIVE_PATH))
end

def write_active(entry)
  File.write(ACTIVE_PATH, JSON.pretty_generate(entry) + "\n")
end

def append_entry(entry)
  File.open(LOG_PATH, "a") { |file| file.puts(JSON.generate(entry)) }
end

def entries
  return [] unless File.exist?(LOG_PATH)

  File.readlines(LOG_PATH, chomp: true).reject(&:empty?).map { |line| JSON.parse(line) }
end

def interval_overlaps?(started_at, ended_at, other_started_at, other_ended_at)
  started_at < other_ended_at && ended_at > other_started_at
end

def ensure_no_overlap!(started_at, ended_at)
  entries.each do |entry|
    other_started_at = parse_time(entry.fetch("started_at"))
    other_ended_at = parse_time(entry.fetch("ended_at"))
    next unless interval_overlaps?(started_at, ended_at, other_started_at, other_ended_at)

    abort("Time range overlaps completed entry #{entry.fetch("started_at")}..#{entry.fetch("ended_at")}")
  end

  active = read_active
  return unless active

  active_started_at = parse_time(active.fetch("started_at"))
  return unless interval_overlaps?(started_at, ended_at, active_started_at, Time.now)

  abort("Time range overlaps the active session that started at #{active.fetch("started_at")}")
end

def format_minutes(value)
  format("%.1f", value.to_f)
end

def generate_report
  rows = entries.sort_by { |entry| parse_time(entry.fetch("started_at")) }
  total = rows.sum { |entry| entry.fetch("duration_minutes").to_f }
  by_category = rows.group_by { |entry| entry.fetch("category") }
                    .transform_values { |items| items.sum { |entry| entry.fetch("duration_minutes").to_f } }

  lines = [
    "# Work Log Summary",
    "",
    "Generated at: #{Time.now.iso8601}",
    "",
    "Total: #{format_minutes(total)} minutes (#{format("%.2f", total / 60.0)} hours)",
    "",
    "## By category",
    "",
    "| Category | Minutes | Hours |",
    "|---|---:|---:|"
  ]

  by_category.sort.each do |category, minutes|
    lines << "| #{category} | #{format_minutes(minutes)} | #{format("%.2f", minutes / 60.0)} |"
  end

  lines.concat([
    "",
    "## Entries",
    "",
    "| Start | End | Minutes | Category | Linear | Estimated | Summary | Outcome |",
    "|---|---|---:|---|---|---|---|---|"
  ])

  rows.each do |entry|
    cells = [
      entry.fetch("started_at"),
      entry.fetch("ended_at"),
      format_minutes(entry.fetch("duration_minutes")),
      entry.fetch("category"),
      Array(entry["issues"]).join(", "),
      entry["estimated"] ? "yes" : "no",
      entry.fetch("summary").to_s.gsub("|", "\\|"),
      entry.fetch("outcome").to_s.gsub("|", "\\|")
    ]
    lines << "| #{cells.join(" | ")} |"
  end

  notes = rows.each_with_object([]) do |entry, result|
    entry_notes = Array(entry["notes"])
    result << [entry, entry_notes] unless entry_notes.empty?
  end

  unless notes.empty?
    lines.concat(["", "## Notes", ""])
    notes.each do |entry, entry_notes|
      lines << "### #{entry.fetch("started_at")} — #{entry.fetch("summary")}"
      lines << ""
      entry_notes.each { |note| lines << "- #{note.fetch("at")}: #{note.fetch("text")}" }
      lines << ""
    end
  end

  File.write(SUMMARY_PATH, lines.join("\n") + "\n")
  puts "Updated #{SUMMARY_PATH}"
end

def with_lock
  File.open(LOCK_PATH, File::RDWR | File::CREAT, 0o644) do |lock|
    lock.flock(File::LOCK_EX)
    yield
  ensure
    lock&.flock(File::LOCK_UN)
  end
end

command = ARGV.shift

with_lock do
  case command
  when "start"
    options = parse_options(ARGV, %i[category summary issues])
    abort("A work-log session is already active. Use note or stop.") if read_active

    entry = {
      "started_at" => Time.now.iso8601,
      "category" => validate_category!(require_option!(options, :category)),
      "summary" => require_option!(options, :summary),
      "issues" => parse_issues(options[:issues]),
      "notes" => []
    }
    write_active(entry)
    puts "Started at #{entry.fetch("started_at")}: #{entry.fetch("summary")}"
  when "note"
    options = parse_options(ARGV, %i[text category])
    active = read_active || abort("No active work-log session")
    active["notes"] << { "at" => Time.now.iso8601, "text" => require_option!(options, :text) }
    if options[:category]
      abort("note --category only supports mixed") unless options[:category] == "mixed"

      active["category"] = "mixed"
    end
    write_active(active)
    puts "Added note"
  when "stop"
    options = parse_options(ARGV, %i[outcome])
    active = read_active || abort("No active work-log session")
    ended_at = Time.now
    started_at = parse_time(active.fetch("started_at"))
    entry = active.merge(
      "ended_at" => ended_at.iso8601,
      "duration_minutes" => ((ended_at - started_at) / 60.0).round(2),
      "outcome" => require_option!(options, :outcome),
      "estimated" => false
    )
    append_entry(entry)
    FileUtils.rm_f(ACTIVE_PATH)
    generate_report
    puts "Stopped after #{format_minutes(entry.fetch("duration_minutes"))} minutes"
  when "add"
    options = parse_options(ARGV, %i[started_at ended_at category summary outcome issues estimated])
    started_at = parse_time(require_option!(options, :started_at))
    ended_at = parse_time(require_option!(options, :ended_at))
    abort("--ended-at must be later than --started-at") unless ended_at > started_at
    abort("Historical entries cannot end in the future") if ended_at > Time.now
    ensure_no_overlap!(started_at, ended_at)

    entry = {
      "started_at" => started_at.iso8601,
      "ended_at" => ended_at.iso8601,
      "duration_minutes" => ((ended_at - started_at) / 60.0).round(2),
      "category" => validate_category!(require_option!(options, :category)),
      "summary" => require_option!(options, :summary),
      "outcome" => require_option!(options, :outcome),
      "issues" => parse_issues(options[:issues]),
      "notes" => [],
      "estimated" => options.fetch(:estimated, false)
    }
    append_entry(entry)
    generate_report
    puts "Added #{format_minutes(entry.fetch("duration_minutes"))} historical minutes"
  when "status"
    active = read_active
    if active
      elapsed = (Time.now - parse_time(active.fetch("started_at"))) / 60.0
      puts JSON.pretty_generate(active.merge("elapsed_minutes" => elapsed.round(2)))
    else
      puts "No active work-log session"
    end
  when "report"
    generate_report
  else
    abort <<~USAGE
      Usage:
        bin/work-log start --category CATEGORY --summary TEXT [--issues LET-1,LET-2]
        bin/work-log note --text TEXT [--category mixed]
        bin/work-log stop --outcome TEXT
        bin/work-log add --started-at ISO --ended-at ISO --category CATEGORY --summary TEXT --outcome TEXT [--issues IDS] [--estimated]
        bin/work-log status
        bin/work-log report
    USAGE
  end
end
