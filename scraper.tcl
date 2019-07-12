#!/usr/bin/tclsh

proc bash_cmd {cmd_str} {
  set f_name [join "tmp [string range [expr rand()] 1 end]" ""]
  set f [ open $f_name "w+" 0755 ]
  puts $f $cmd_str
  close $f
  exec "[pwd]/$f_name" > /dev/null 2>/dev/null
  file delete -force "[pwd]/$f_name"
}

proc url_absolute { base_url rel_url } {
  # return rel_url if it is already absolute url
  if {[string equal [string range $rel_url 0 3] http]} {
    return $rel_url
  }

  set rel_url_list [ split $rel_url "/" ]
  set base_url_list [lrange [ split $base_url "/"] 0 end-1]

  #remove any unnecessary parent dir ref from rel_url_list
  if {[string equal [lindex rel_url_list 0] {.}]} {
    set rel_url_list [lrange rel_url_list 1 end]
  }

  # travers through parent directories
  while {[string equal [lindex $rel_url_list 0] {..}]} {
    set base_url_list [lrange $base_url_list 0 end-1]
    set rel_url_list [lrange $rel_url_list 1 end]
  }
  
  #combine base and relative url lists and return combined url
  set full_url_list [concat $base_url_list $rel_url_list]
  return [join $full_url_list "/"]
}

proc url_pretty { url } {
  return [string map {href= {}} [join [regexp -all -inline {[[:alnum:]\:\/\.\_\-\~\?\=\&]+} $url] ""]]
}

proc web_crawl { url_base } {
  # note that urls are assumed absolute not relative
  set page_name "[pwd]/page.html"
  set urls $url_base 
  set i 0
  while {[llength $urls] && $i < 5} {
    bash_cmd "wget [lindex $urls 0] -O $page_name"

    # add top of url stack to visited list
    lappend visited [lindex $urls 0]

    #load page html
    set f [open $page_name "r"]
    set page [read $f]

    # get all relevant links from page
    set urls_new [regexp -all -inline -- {href="[^"]+"} $page]


    # add all new urls to the stack 
    foreach u_ugly $urls_new {
      set rel_url [url_pretty $u_ugly]
      set abs_url [url_absolute [lindex $urls 0] $rel_url]
      set url_unseen 0
      foreach u_seen $visited {
        if {[string equal $abs_url $u_seen]} {
          set url_unseen 1
          break
        }
      } 
      if {! $url_unseen } {
        lappend urls $abs_url
      }
    }
    # pop top of URL stack
    puts [lindex $urls 0]
    set urls [lrange $urls 1 end]
    incr i
  }

  #cleanup unecessary files
  file delete -force "$page_name"

  return $urls 
}

web_crawl {https://www.webmd.com/}
# web_crawl {http://books.toscrape.com/catalogue/category/books/history_32/index.html}
# web_crawl {https://en.wikipedia.org/wiki/Main_Page}
