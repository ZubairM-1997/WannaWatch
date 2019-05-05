require 'uri'
require 'net/http'
require 'pry'
require 'json'
require_all 'app'

def fetch(page=1)
    #API pull code generated by TMDB
    url = URI("https://api.themoviedb.org/3/movie/upcoming?page=#{page}&language=en-US&api_key=be6bc01e83db5bd420caf0e567ab2965")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request.body = "{}"

    response = http.request(request)
    return results_hash = JSON.parse(http.request(request).read_body)
end

def fetch_all_pages
    page_count = fetch["total_pages"]
    page = 1
    arr_movies = []

    page_count.times do
        arr_results = fetch(page)["results"]
        arr_results.each { |movie| arr_movies << movie}
        page += 1
    end
    return arr_movies
end

def get_genres
    #API pull code generated by TMDB
    url = URI("https://api.themoviedb.org/3/genre/movie/list?language=en-US&api_key=be6bc01e83db5bd420caf0e567ab2965")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url)
    request.body = "{}"

    results = JSON.parse(http.request(request).read_body)

    genres_hash = {}
    results["genres"].each do |genre|
        genres_hash[genre["id"]] = genre["name"]
    end
    return genres_hash
end

def update_upcoming_movies(arr_movies)
    genres = get_genres
    arr_movies.each do |movie_params|
        Movie.create_with(
            description: movie_params["overview"],
            release_date: Date.strptime(movie_params["release_date"],"%Y-%m-%d"),
            title: movie_params["title"],
            genre: movie_params["genre_ids"].map{ |genre_num| genres[genre_num] }.join(', ')
            )
        .find_or_create_by(tmdb_id:movie_params["id"])
    end
end

def master_update
    update_upcoming_movies(fetch_all_pages)
end
