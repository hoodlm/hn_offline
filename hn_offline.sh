#! /usr/bin/bash
set -eu
set -o pipefail

# --------------------------------------------------------------------
# Usage: download "news.ycombinator.com/front?day=2023-01-27" "./out/index.html"
download() {
  local url=$1
  local download_outdir=$2

  printf "Downloading %s to %s\n" "${url}" "${download_outdir}"
  pushd "$download_outdir"
  wget \
    --recursive --level=1 \
    --accept-regex ".*item.+" \
    --page-requisites \
    --relative \
    --adjust-extension \
    --convert-links \
    --limit-rate=50k \
    --wait=60 --random-wait \
    --progress=dot \
    "$url"
  popd
}

cleanup_converted_files() {
  local download_outdir=$1
  find "$download_outdir" -not -name "*[html|txt|css|keep]" \
    -exec rm -v {} \;
}

overwrite_index() {
  local front_page=$1
  local out_dir=$2

  local destination_file_name="index.html"

  local source_file
  source_file=$(find "$out_dir" | grep "$front_page")
  local directory
  directory=$(dirname "$source_file")

  cp -v "$source_file" "${directory}/${destination_file_name}"
}

do_download() {
  local out_dir="./out"
  local target_site="news.ycombinator.com"
  local front_page
  if [ -z "${extracted_date:-}" ]; then
    front_page="${target_site}"
  else
    front_page="${target_site}/front?day=${extracted_date}"
  fi

  download "${front_page}" "${out_dir}"
  cleanup_converted_files "${out_dir}"

  # 'overwrite_index' is only required when frontpage
  # for a specific date was downloaded
  if [ -n "${extracted_date:-}" ]; then
    overwrite_index "${front_page}" "${out_dir}"
  fi
}

error() {
  printf "Error: %s\n" "$1"
  exit 1
}

handle_args() {
  if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "USAGE: $0 [--date <YYYY-MM-DD>]"
    echo "OPTIONS:"
    echo "  --date   Download the front page from a specific date"
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
