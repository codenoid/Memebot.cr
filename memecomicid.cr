require "db" # 3rd party - crystal official
require "sqlite3" # 3rd party - crystal official
require "modest" # 3rd party
require "myhtml" # 3rd party
require "http/client" # FROM CRYSTAL

Data = DB.open "sqlite3://./memebot.db" # Actually, File.open to your sqlite database

(0...300).each do |i| # max 300 page
    # do multi forking is `i` is odd number
    i.odd? ? fork { getMeme(i) } : getMeme(i)
end

 # main function, crawler a page (from pagination), and 'catch em all meme'
def getMeme(i)
  a = HTTP::Client.get("https://www.memecomic.id/async/all?page=#{i}", headers: HTTP::Headers{"X-Requested-With" => "XMLHttpRequest"})
  if a.success?
    b = a.body
    c = Myhtml::Parser.new(b)
    images = c.css(".mci-postimg img").map(&.attribute_by("src")).to_a # we got image
    title = c.css(".mci-poststatus span").map(&.inner_text).to_a # we got caption
    ids = c.css(".mci-post").map(&.attribute_by("id")).to_a # we got post id
    (0...images.size).each do |i| # each all images (memes)
      id = ids[i]
      img = images[i].to_s
      # i dont need "old" meme (basi)
      check = Data.query_one? "select title from main_posts where ukey=? limit 1", id, as:{String}
      if !check && img != "https://www.memecomic.id/media/ifyouknow.jpg"
        t = title[i]
        puts "[INSERT] #{t} - #{Time.now}" # info to STDOUT
        date = Time.now.epoch
        li = img.split("/").last.to_s + Time.now.epoch.to_s + ".jpg"
        d = HTTP::Client.get img
        # is my http client success load the image ?, if success (200...299), call downloadImage(), with response body
        d.success? ? downloadImage(li, d.body) : puts "Fail save image"
        Data.exec "insert into main_posts (title,image,date,ukey,localimage) values (?,?,?,?,?)", t, img, date, id, li
        Data.close # Close file.open !
      end
    end
  end
end

# just a simple function to download ALL MEMES
# LET'S SPREAD ALL OF THIS MEME
# GOD LOVE <3 MEME
def downloadImage(name, file)
  File.write("images/" + name, file)
end
