module GenIndexJson
  require "yaml"
  require "json"

  class << self
    TARGET_PATH = "/../../posts".freeze

    def generate_full
      collect_posts
      parse_all
      descending_sort_by_timestamp
      put_frontmatter_jsonfile(to_json)

      return
    end

    def generate
    end

    private

    def root_dir
      "#{File.dirname(__FILE__)}#{TARGET_PATH}"
    end

    def collect_posts
      years = Dir.entries(root_dir).select { |f| /\d{4}/ =~ f }

      @posts_path = []
      years.each do |d|
        Dir.entries("#{root_dir}/#{d}").each do |f|
          next if ["..", "."].include? f
          @posts_path << [d, f]
        end
      end
    end

    def parse_all
      @posts = []
      @posts_path.each { |a| parse(a[0], a[1]) }
    end

    def parse(year, filename)
      body = read_md(year, filename)
      raw_frontmatter, raw_contents = split(body)
      frontmatter = parse_frontmatter(raw_frontmatter)
      frontmatter = insert_id(frontmatter, "#{year}/#{filename}")

      @posts << { frontmatter: frontmatter, contents: raw_contents }
    end

    def read_md(year, filename)
      root_dir = "#{File.dirname(__FILE__)}#{TARGET_PATH}"
      File.readlines("#{root_dir}/#{year}/#{filename}").join
    end

    def split(body)
      first = body.index("---")
      second = body.index("---", first + 1)

      frontmatter = body[first + 3 .. second - 1].strip
      contents = body[second + 3 .. ].strip

      return frontmatter, contents
    end

    def parse_frontmatter(raw_frontmatter)
      YAML.load(raw_frontmatter)
    end

    def insert_id(frontmatter, id)
      { id: id[5 ..].sub(/\.md$/, "") }.merge(frontmatter)
    end

    def to_json
      JSON.pretty_generate(@posts.map{ |a| a[:frontmatter] })
    end

    def descending_sort_by_timestamp
      @posts.sort!{ |a, b| b[:frontmatter]["created_at"] <=> a[:frontmatter]["created_at"] }
    end

    def put_frontmatter_jsonfile(json)
      File.write("#{root_dir}/index.json", json)
    end
  end
end
