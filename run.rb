require 'dotenv/load'
require 'logger'
require 'csv'
require 'semantic_logger'
require_relative 'lib/practice_portuguese'

SemanticLogger.add_appender(io: $stdout, formatter: :color)
SemanticLogger.default_level = :info

logger = SemanticLogger['App']

# Configuration
USERNAME = ENV['USERNAME']
PASSWORD = ENV['PASSWORD']
WORD_LIMIT = ENV.fetch('WORD_LIMIT').to_i

unless USERNAME && PASSWORD
  logger.error("Username and password must be set in .env file")
  exit 1
end

logger.info("Adding #{WORD_LIMIT} most popular words to smart review")

pp = PracticePortuguese.new(USERNAME, PASSWORD)
pp.login
pp.get_phrases

words = CSV.readlines('data/words.csv')
logger.info("Loaded #{words.size} words from file")

# Process each word up to limit
words.first(WORD_LIMIT).each do |line|
  word = line[0]
  logger.info("\nProcessing word: #{word}")

  unless pp.add_to_smart_review(word)
    print("\nPress Enter to continue to the next word (or type 'q' to quit): ")
    input = gets.chomp.downcase
    break if input == 'q'
  end
end
