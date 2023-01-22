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
# typically: comment_links ./out/index.html ./tmp
extract_comment_links() {
  local html_file=$1
  local tmp_dir=$2

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

  echo "${comment_urls}" > "${tmp_dir}/comments.txt"
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

do_download() {
  local tmp_dir="./tmp"
  local out_dir="./out"
  local target_site="news.ycombinator.com"
  local front_page
  if [ -z "${extracted_date:-}" ]; then
    front_page="${target_site}"
  else
    front_page="${target_site}/front?day=${extracted_date}"
  fi

  printf "Cleaning %s directory\n" "${tmp_dir}"
  rm ${tmp_dir}/* || true

  printf "Removing existing index.html, if any\n"
  rm "${out_dir}/index.html" || true

  download "${front_page}" "${out_dir}/index.html"
  extract_comment_links "${out_dir}/index.html" "${tmp_dir}"
  sanitize_comment_links "${out_dir}/index.html"
  download_pages_from_file "${target_site}" "${tmp_dir}/comments.txt" "${out_dir}"
}

error() {
  printf "Error: %s\n" "$1"
  exit 1
}

handle_args() {
  if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "USAGE: $0 [--date YYYY-MM-DD]"
    exit 0
  fi

  local date_arg
  date_arg=$(echo "$@" | grep -E -o "\-\-date \S+")

  if [ -n "${date_arg}" ]; then
    extracted_date=$(echo "${date_arg}" | grep -E -o "[[:digit:]]{4}\-[[:digit:]]{2}\-[[:digit:]]{2}$") \
      || error "Date must match YYYY-MM-DD format (e.g. 2023-01-19). Argument supplied was: \"${date_arg}\""
  fi
}

# --------------------------------------------------------------------
main() {
  if [ $# -gt 0 ]; then
    handle_args "$@"
  fi
  do_download
}

main "$@"
