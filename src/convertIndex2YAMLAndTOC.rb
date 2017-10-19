#!/usr/bin/ruby
# Converts Confluence exported index.md content hierarchy file exported with https://github.com/coveo/confluence-to-markdown
# into a YAML TOC tree file taking ids from the idFile. Liquid templates can read this TOC tree fiel to build HTML TOCs and breadcrumbs.
# 
# usage:    src/convertIndex2YAMLAndTOC.rb sourceFile targetTocFile outputPathPrefix idFile
# ex:       From this project root folder:
#           src/convertIndex2YAMLAndTOC.rb "../cloudv2-docs-site/_ccv2-dev/index.md" "../cloudv2-docs-site/_data/tocs/testtoc.yml" "_ccv2-dev/" "../cloudv2-docs-site/_data/ids.yml"

# Get command line arguments
sourceFile = ARGV[0]
targetTocFile = ARGV[1]
outputPathPrefix = ARGV[2]
idFile = ARGV[3]

# YAML module needed to manage YAML file
require 'yaml'

# Target TOC file preambule comments and 'entries:' line
preambule = %(# Section Table of Content
#
# Name TOC file with name of parent folder where files reside
# List all items to include in the TOC from a folder in the desired hierarchy with the following syntax:
# entries:
# - title: The TOC Entry Text                             # Can be different from the page.title
#   path: /full/path/with/the/filename.html
#   subentries:                                           # When the entry has subentries

entries:
)

# Function to find the id of the page matching the specified path
def findId(idFile,filePath)
    # Load items from the idFile YAML content
    ids = YAML.load_file(idFile)
    items = ids['items']
    # Find the highest used id value
    id = 0 
    items.each do |n|
        itemPath = n['path']
        if filePath == itemPath
            id = n['id']
        end
    end
    return id
end 

# REGEX matching the source file lines with markdown links and capturing indentation, title and path
EntryPattern = /^(\s*)[-]\s\s\s\[([^\]]+)\]\(([^)]+)\)/     
# Initializing variables
indentPos = 1
indentLength = 2
prevIndentLength = 2
prevIndent = ""
first = true

# Set the 1st level parentPath
firstLevelParentSourcePath = outputPathPrefix + 'index.md'
firstLevelParentPath = '/' + findId(idFile,firstLevelParentSourcePath).to_s + '/'
breadcrumbPath = [firstLevelParentPath]
prevPagePath = firstLevelParentPath

# Opening and writing to the target TOC file
File.open(targetTocFile, 'w') do |f|
    f.puts preambule
    # Opening and reading the source file
    File.open(sourceFile, "r").each_line do |line|
        # Do nothing with the first link (Confluence space root file that we do not want to reproduce in TOC)
        if (line =~ EntryPattern and first)
            first = false
        # Write only for lines matchning the REGEX
        elsif (line =~ EntryPattern )
            # Get the line useful elements
            indent, title, path = line.match(EntryPattern).captures
            # Source file indentation is twice what it should be in the YAML output
            indentPos = (indent.length/4)
            indentLength = indent.length/2
            halfIndent = indent[0,indentLength-2]

            if (indentPos > breadcrumbPath.length )
                # Add the prevPagePath to the breadcrumbPath
                breadcrumbPath.push(prevPagePath)
            elsif (indentPos < breadcrumbPath.length)
                # Reduce breadcrumb length to that od indentPos
                breadcrumbPath = breadcrumbPath.first(indentPos)
            end

            # Add 'subentries' when indent increases
            if (indentLength > prevIndentLength)
                f.puts prevIndent + "  subentries:"
            end
            # Set the page path
            pageSourcePath = outputPathPrefix + path + ".md"
            puts 'pageSourcePath: ' + pageSourcePath
            # Get the page id
            pageId = findId(idFile,pageSourcePath)
            puts 'pageId: ' + pageId.to_s
            # Write the entry information
            f.puts ""
            f.puts halfIndent + '- title: ' + title
            f.puts halfIndent + '  source: ' + pageSourcePath
            f.puts halfIndent + '  path: /' + pageId.to_s + '/'
            f.puts halfIndent + '  parentPath: ' + breadcrumbPath[-1].to_s
            
            # puts 'indentPos: ' + indentPos.to_s
            # puts 'breadcrumbPath.length: ' + breadcrumbPath.length.to_s
            # puts 'breadcrumbPath: ' + breadcrumbPath.map { |i| "'" + i.to_s + "'" }.join(",")
            # puts

            # Prepare for the next entry
            prevIndentLength = indentLength
            prevIndent = halfIndent
            prevPagePath = '/' + pageId.to_s + '/'
        end
    end
end
