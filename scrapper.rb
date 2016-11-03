require 'bundler'
require 'irb'
Bundler.require
# ALPHABETS = %w(a b c d e f g h i j)
ALPHABETS = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
KBBI_URL  = 'http://kbbi4.portalbahasa.com'
threads = []

EXTENSI_ERROR = ' - error'
# Thread.abort_on_exception = true

class Counter
  @@count = 0
  def self.add
    @@count += 1
  end
  def count
    @@count
  end
end

def get_word(nokogiri_html)
  words = ""
  nokogiri_html.css(".col-xs-6.col-sm-4.col-md-3").each do |word|
    words += "#{word.text}\n"
  end
  words
end

def get(url)
  Curl.get(url)
end

def parse(html)
  Nokogiri::HTML(html)
end

def get_html(url)
  parse(get(url).body)
end

def terakhir_error(alphabet)
  File.read(nama_error(alphabet)) rescue nil
end

def nama_error(alphabet)
  save_location(alphabet) + EXTENSI_ERROR
end

def scrape_url(alphabet)
  if File.exists?(nama_error(alphabet))
    terakhir_error(nama_error(alphabet))
    FileUtils.remove(nama_error(alphabet))
  else !File.exists?(alphabet)
    KBBI_URL + '/berawalan/' + alphabet
  end
end

def save_location(alphabet)
  'words/' + alphabet
end

def log_alamat(log)
  File.open('logs/alamat.log', 'w') do |f|
    f.write(log + "\n")
  end
end


ALPHABETS.each do |alphabet|
  threads << Thread.new do |variable|
    break unless scrape_url(alphabet)
    file  = File.open(save_location(alphabet), "w")
    alamat = scrape_url(alphabet)
    html = get_html(alamat)
    file.puts(get_word(html))
    begin
      while(true) do
        puts Counter.add
        arrow = html.css(".glyphicon.glyphicon-triangle-right").first
        if arrow
          next_url = arrow.parent.attr('href')
          break unless next_url
          log_alamat(KBBI_URL + next_url)
          html = get_html(KBBI_URL + next_url)
          file.puts(get_word(html))
        else
          break
        end
      end
    rescue => e
      File.open(nama_error(alphabet), 'a') do |f|
        f.write(KBBI_URL + next_url)
      end if next_url != '#'
      puts e.message
    ensure
      file.close
    end
  end
end
threads.map(&:join)

