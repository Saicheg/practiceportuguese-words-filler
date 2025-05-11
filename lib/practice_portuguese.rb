require 'semantic_logger'
require_relative 'practice_portuguese_client'

class PracticePortuguese
  def initialize(username, password)
    @username = username
    @password = password
    @logger = SemanticLogger['PracticePortuguese']
    @token = nil
    @phrases = []
    @client = PracticePortugueseClient.new
  end

  def login
    logger.info("Logging in...")
    @token = @client.login(@username, @password)
  end

  def get_phrases
    logger.info("Getting phrases...")
    @phrases = @client.get_phrases(@token)
    
    # Pre-process phrases to add individual words
    @phrases.each do |phrase|
      add_pt_phrases_to_phrase(phrase)
    end
  end

  def add_to_smart_review(word)
    logger.info("Processing word: #{word}")

    # Check if word already exists in current phrases using pre-processed words
    existing_phrase = @phrases.find do |phrase|
      phrase["pt_words"].include?(word.downcase)
    end
    
    if existing_phrase
      logger.info("Word '#{word}' already exists in phrases")
      return true
    end

    # Search for the word in the system
    search_results = @client.search_phrases(word, @token)
    
    if search_results.empty?
      logger.info("No phrases found for word '#{word}'")
      return false
    end

    # Find the best matching phrase (prefer nouns over other types)
    best_phrase = search_results.find { |p| p['phrase_type'] == 'Noun' } || search_results.first
    
    logger.info("Found phrase: #{best_phrase['pt']} (#{best_phrase['translation']})")
    
    # Add the phrase to smart review
    success = @client.add_phrase_to_smart_review(best_phrase['ID'], @token)
    
    if success
      logger.info("Successfully added phrase to smart review")
      add_pt_phrases_to_phrase(best_phrase)
      @phrases << best_phrase
      return true
    else
      logger.error("Failed to add phrase to smart review")
      return false
    end
  end


  private
  
  attr_reader :logger

  def add_pt_phrases_to_phrase(phrase)
    pt_words = phrase["pt"].downcase.split(/\s+/)
    phrase["pt_words"] = pt_words
  end
end 
