require "colorize"

class Game
  property length = 0

  # This embeds the DB in the binary, which is for now easier for Beta-Testing
  RAW_DATA = {{ `cat #{__DIR__}/eng-words.txt`.stringify }}
  def initialize
    @lists = {} of Int32 => Array(String)
    load_raw_data
    # load_words("eng-words.txt")
  end

  def load_raw_data
    RAW_DATA.split("\n").each do |word|
      @lists[word.size] ||= [] of String
      @lists[word.size] << word
    end
  end

  def load_words(filename)
    File.open(filename) do |txt|
      while word = txt.gets
        @lists[word.size] ||= [] of String
        @lists[word.size] << word
      end
    end
  end

  def clear_screen
    print "\33c\e[3J"
  end

  def menu
    puts "WORDL-Clone"
    puts "==========="
    puts
    puts "How to play?"
    puts "------------"
    puts "- You have 6 attempts to guess a word"
    # TODO, this:
    # puts "- All attempts must be valid words (no ASDFG)"
    puts "- Your guess will be colorized"
    print "- ", "yellow".colorize(:yellow)
    puts " = character is correct but on the wrong position"
    print "- ", "green".colorize(:green)
    puts " = character is correct"
    puts
    puts "How long shall the word be? (#{@lists.keys.sort.join(", ")})"
    @length = (STDIN.gets || "0").to_i
    unless @lists.keys.includes?(length)
      puts "Invalid length: #{length}"
      exit(1)
    end
  end

  def colored_guess(word, ref)
    return word if word.includes?('_')

    new_word = ""
    word.size.times do |idx|
      if word[idx] == ref[idx]
        new_word += word[idx].colorize(:green).to_s
      elsif ref.includes?(word[idx])
        new_word += word[idx].colorize(:yellow).to_s
      else
        new_word += word[idx]
      end
    end
    new_word
  end

  def board(unused_chars, guesses, word_to_guess)
    clear_screen
    puts "Unused Characters: #{unused_chars.join(' ')}"
    puts
    guesses.each_with_index do |word, idx|
      print idx+1, ") "
      puts colored_guess(word, word_to_guess)
    end
    puts
  end

  def play(max_guesses=6)
    word_to_guess = @lists[length].sample
    guesses = [] of String
    max_guesses.times do
      guesses << ("_" * length)
    end
    unused_chars = ('A'..'Z').to_a

    max_guesses.times do |round|
      board(unused_chars, guesses, word_to_guess)
      puts
      word = nil
      loop do
        print "Try (#{round+1}/#{max_guesses}): "
        word = STDIN.gets
        if word.nil? || word.size != length
          puts "ERROR: Invalid Input"
          next
        end
        break
      end
      raise "Something is broken" if word.nil?

      word = word.upcase
      unused_chars -= word.each_char.to_a
      guesses[round] = word
      if word == word_to_guess
        board(unused_chars, guesses, word_to_guess)
        puts "+---------+"
        puts "| YOU WON |"
        puts "+---------+"
        puts

        return
      end
    end

    board(unused_chars, guesses, word_to_guess)
    puts "+-----------+"
    puts "| YOU LOOSE |"
    puts "+-----------+"
    puts
    puts "The word was: #{word_to_guess}"
  end
end

g = Game.new
g.menu
g.play
