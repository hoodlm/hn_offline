#! /usr/bin/bash
set -eu
set -o pipefail

# --------------------------------------------------------------------
# Usage: download "news.ycombinator.com" "./out/index.html"
download() {
  local url=$1
  local download_outfile=$2


  printf "Downloading %s to %s\n" "${url}" "${download_outfile}"
  wget --quiet "$url" -O "${download_outfile}"

  # respect HN's robots.txt directive 'Crawl-delay: 30'
  local sleep_seconds=31
  printf "Waiting %s seconds between downloads\n" "${sleep_seconds}"
  sleep "${sleep_seconds}"
}

# --------------------------------------------------------------------
# Comment links on HN follow the format like "item?id=34466855"
# where id is a parameter to a backend webserver. Since we're just
# saving these as static HTML, and it's a pain to work with unix
# files with question marks in them, I'm just stripping out
# the '?' from all comment URLs.
sanitize_comment_links() {
  sed "s/item?id/itemid/g" -i "$1"
}

# --------------------------------------------------------------------
# obligatory before we go further,
# https://stackoverflow.com/a/1732454
#
# "we shall surely both die if you parse html with
# regular expressions," said the Frog.
# "lol" said the Scorpion, "lmao"


# --------------------------------------------------------------------
# Extract all 'comment' links from the hacker news frontpage
# and writes them to ./tmp/comments.txt
# 
# typically: comment_links ./out/index.html
extract_comment_links() {
  local html_file=$1

  local comment_urls

  # the first regex will give you a list of things like
  #   <a href="item?id=34466855">46&nbsp;comments</a>
  # then the second strips out just the first double-quoted segment:
  #   "item?id=34466855"
  # and finally a sed command to remove the double quotes:
  #   item?id=34466855

  comment_urls=$(\
    grep -E -o "<a href=\"[^<>]+\">[^<>]+comments</a>" "$html_file" \
    | grep -E -o "\".+\"" \
    | sed 's/\"//g')

  echo "${comment_urls}" > ./tmp/comments.txt
}

# --------------------------------------------------------------------
# Download sub-pages read from a file.
# $1 is the hostname/homepage (e.g. example.org)
# $2 is the filename
# $3 is the out directory (e.g. ./out)
#
# The contents of the file should be one page per line. For example,
# if it looks like this:
#
#   example1.html
#   example2.html
#
# Then this function would download these pages to ./out:
#   example.org/example1.html
#   example.org/example2.html
#
# typically: download_pages_from_file news.ycombinator.com ./tmp/comments.txt ./out
download_pages_from_file() {
  local base_url=$1
  local in_file=$2
  local out_dir=$3

  while IFS= read -r subpage; do
    local dest_file
    dest_file="${out_dir}/${subpage}"

    # same hack to strip question-marks from filenames; see sanitize_comment_links
    dest_file=${dest_file/item?id/itemid}

    download "${base_url}/${subpage}" "${dest_file}"
  done < "${in_file}"
}


# --------------------------------------------------------------------
main() {
  printf "Clearing ./tmp and ./out directories\n"
  rm ./tmp/* || true
  rm ./out/* || true

  download "news.ycombinator.com" "./out/index.html"
  extract_comment_links "./out/index.html"
  sanitize_comment_links "./out/index.html"
  download_pages_from_file "news.ycombinator.com" "./tmp/comments.txt" "./out"
}

main
