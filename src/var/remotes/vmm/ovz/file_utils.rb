# -------------------------------------------------------------------------- #
# Copyright 2002-2011, OpenNebula Project Leads (OpenNebula.org)             #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

require 'scripts_common'

class File
  # Helper method used to create symlink in directories available only to root user
  # For example: /vz/template/cache
  def self.symlink source, target
    OpenNebula.exec_and_log "sudo ln -s #{source} #{target}"
  end

  # Helper method used to remove file in directories available only to root user
  def self.delete what
    OpenNebula.exec_and_log "sudo rm -rf #{what}"
  end
end

module OpenNebula
  #  FileUtils groups utilities performing actions on files
  class FileUtils
    #  An utility used to determine archive type
    #
    # * *Args*    :
    #   - +file_name+ -> name of the file to be checked
    # * *Returns* :
    #   - archive type, currently one of these values: 'tar.gz', 'tar.bz2', 'tar.xz' (only these are supported by OpenVz)
    def self.archive_type(file_name)
      # compression type is determined by 2 bytes representing 'magic number'
      types = {"\x1F\x8B" => 'tar.gz', "BZ" => 'tar.bz2', "\xFD\x00" => 'tar.xz'}

      File.open(file_name, "r") do |file|
        bytes = file.read(2)
        return types[bytes] if types[bytes]
      end

      raise "Cannot determine filetype of #{file_name}"
    end

    #  An utility used to filter executable filenames
    #
    # * *Args*    :
    #   - +files+ -> String containing filenames separated by whitespaces
    # * *Returns* :
    #   - Filtered array containing only executable filenames. If none of the filenames matches, the empty array is returned
    def self.filter_executables(files)
      # allowed executable extensions
      exts = %w(.sh .ksh .zsh)

      return [] if files.nil? or files.empty?
      files.split.find_all {|f| exts.find {|e| e == File.extname(f) } != nil }
    end

  end

end