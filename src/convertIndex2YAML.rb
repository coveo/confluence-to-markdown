#!/usr/bin/ruby
# Converts Confluence exported index.md content hierarchy file exported with https://github.com/coveo/confluence-to-markdown
# into a YAML toc file to use in Jekyll to build TOCs and breadcrumbs.
# 
# usage:    convertIndex2YAML.rb sourceFile targetFile outputPathPrefix
# ex:       convertIndex2YAML.rb "../../cloudv2-docs-site/pages/ccv2-dev/index.md" "../../cloudv2-docs-site/_data/tocs/testtoc.yml" "pages/ccv2-dev/"

sourceFile = ARGV[0]
targetFile = ARGV[1]
outputPathPrefix = ARGV[2]

# Preambule comments and 'entries:' line
preambule = %(# Section Table of Content
#
# Name TOC file with name of parent folder where files reside
# List all items to include in the TOC from a folder in the desired hierarchy with the following syntax:
# entries:
# - title: The TOC Entry Text                             # Can be different from the page.title
#   path: full/relative/path/with/the/filename.html
#   subentries:                                           # When the entry has subentries

entries:
)

EntryPattern = /^(\s*)[-]\s\s\s\[([^\]]+)\]\(([^)]+)\)/     # REGEX matching the lines with markdown links and capturing indentation, title and path
prevIndentLength = 0
prevIndent = ""
# Opening and writing to the target file
File.open(targetFile, 'w') do |f|
    f.puts preambule
    # Opening and rending the source file 
    File.open(sourceFile, "r").each_line do |line|
        # Write only for lines matchning the REGEX
        if (line =~ EntryPattern)
            # Get the line useful elements
            indent, title, path = line.match(EntryPattern).captures
            # Source file indentation is twice what it should be in the YAML output
            indentLength = indent.length/2
            halfIndent = indent[0,indentLength]
            # Add 'subentries' when indent increases
            if (indentLength > prevIndentLength)
                f.puts prevIndent + "  subentries:"
            end
            # Write the entry information
            f.puts ""
            f.puts halfIndent + '- title: ' + title
            f.puts halfIndent + '  path: ' + outputPathPrefix + path + ".html"
            # Prepare for the next entry
            prevIndentLength = indentLength
            prevIndent = halfIndent
        end 
    end
end