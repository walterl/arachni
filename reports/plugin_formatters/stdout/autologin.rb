=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports

class Stdout
    module PluginFormatters

        #
        # Stdout formatter for the results of the AutoLogin plugin
        #
        #
        # @author: Tasos "Zapotek" Laskos
        #                                      <tasos.laskos@gmail.com>
        #                                      <zapotek@segfault.gr>
        # @version: 0.1
        #
        class AutoLogin < Arachni::Plugin::Formatter

            def initialize( plugin_data )
                @results = plugin_data[:results]
                @description = plugin_data[:description]
            end

            def run
                print_status( 'AutoLogin' )
                print_info( '~~~~~~~~~~~~~~' )

                print_info( 'Description: ' + @description )
                print_line
                print_ok( @results[:msg] )

                return if !@results[:cookies]
                print_info( 'Cookies set to:' )
                @results[:cookies].each_pair {
                    |name, val|
                    print_info( '    * ' + name + ' = ' + val )
                }
            end

        end

    end
end

end
end
