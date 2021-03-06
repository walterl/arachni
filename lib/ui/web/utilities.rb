=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module UI
module Web

#
# General utility methods.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
module Utilities

    #
    # Escapes HTML chars.
    #
    # @param    [String]    str
    #
    # @return   [String]
    #
    # @see CGI.escapeHTML
    #
    def escape( str )
        CGI.escapeHTML( str )
    end

    #
    # Unescapes HTML chars.
    #
    # @param    [String]    str
    #
    # @return   [String]
    #
    # @see CGI.unescapeHTML
    #
    def unescape( str )
        CGI.unescapeHTML( str )
    end

    #
    # Recursively escapes all HTML characters.
    #
    # @param    [Hash]  hash
    #
    # @return   [Hash]
    #
    def escape_hash( hash )
        hash.each_pair {
            |k, v|
            hash[k] = escape( hash[k] ) if hash[k].is_a?( String )
            hash[k] = escape_hash( v ) if v.is_a? Hash
        }

        return hash
    end

    #
    # Recursively unescapes all HTML characters.
    #
    # @param    [Hash]  hash
    #
    # @return   [Hash]
    #
    def unescape_hash( hash )
        hash.each_pair {
            |k, v|
            hash[k] = unescape( hash[k] ) if hash[k].is_a?( String )
            hash[k] = unescape_hash( v ) if v.is_a? Hash
        }

        return hash
    end

    #
    # Parses datetime strings such as 07/23/2011 15:34 into Time objects.
    #
    # @param    [String]    datetime
    #
    # @return   [Time]
    #
    def parse_datetime( datetime )
        date, time = datetime.split( ' ' )

        month, day, year = date.split( '/' )
        hour, minute     = time.split( ':' )

        Time.new( year, month, day, hour, minute )
    end

    #
    # Constructs an instance URL by port using its dispatcher's url.
    #
    # @param    [Integer]   port
    # @param    [String]   dispatcher_url   URL of the dispatcher
    # @param    [Bool]     no_scheme        include scheme in the URL?
    #
    # @return   [String]
    #
    def port_to_url( port, dispatcher_url, no_scheme = nil )
        uri = URI( dispatcher_url )
        uri.port = port.to_i
        uri = uri.to_s

        uri = remove_proto( uri ) if no_scheme
        return uri
    end

    #
    # Removes the protocol from URL string.
    #
    # @param    [String]    url
    #
    # @return   [String]
    #
    def remove_proto( url )
        url.gsub!( 'http://', '' )
        escape( url.gsub( 'https://', '' ) )
    end

end
end
end
end
