=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'erb'
require 'base64'
require 'cgi'
require 'iconv'

module Arachni

require Options.instance.dir['lib'] + 'crypto/rsa_aes_cbc'

module Reports

#
# Creates an HTML report of the audit.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2.2
#
class HTML < Arachni::Report::Base

    REPORT_FP_URL = "https://arachni.segfault.gr/false_positive"

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]   options    options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store   = audit_store
        @options       = options

        @crypto = RSA_AES_CBC.new( Options.instance.dir['data'] + 'crypto/public.pem' )
    end

    #
    # Runs the HTML report.
    #
    def run( )

        print_line( )
        print_status( 'Creating HTML report...' )

        report = ERB.new( IO.read( @options['tpl'] ) )

        __prepare_data

        @plugins = format_plugin_results( @audit_store.plugins )

        conf = {}
        conf['options']  = @audit_store.options
        conf['version']  = @audit_store.version
        conf['revision'] = @audit_store.revision
        conf = @crypto.encrypt( conf.to_yaml )

        __save( @options['outfile'], report.result( binding ) )

        print_status( 'Saved in \'' + @options['outfile'] + '\'.' )
    end

    def self.info
        {
            :name           => 'HTML Report',
            :description    => %q{Exports a report as an HTML document.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.2',
            :options        => [
                Arachni::OptPath.new( 'tpl', [ false, 'Template to use.',
                    File.dirname( __FILE__ ) + '/html/default.erb' ] ),
                Arachni::OptString.new( 'outfile', [ false, 'Where to save the report.',
                    Time.now.to_s + '.html' ] ),
            ]
        }
    end

    private

    def js_multiline( str )
      "\"" + str.gsub( "\n", '\n' ) + "\"";
    end

    def normalize( str )
        return str if !str || str.empty?

        ic = ::Iconv.new( 'UTF-8//IGNORE', 'UTF-8' )
        ic.iconv( str + ' ' )[0..-2]
    end

    def escapeHTML( str )
        # carefully escapes HTML and converts to UTF-8
        # while removing invalid character sequences
        return CGI.escapeHTML( normalize( str ) )
    end

    def self.prep_description( str )
        placeholder =  '--' + rand( 1000 ).to_s + '--'
        cstr = str.gsub( /^\s*$/xm, placeholder )
        cstr.gsub!( /^\s*/xm, '' )
        cstr.gsub!( placeholder, "\n" )
        cstr.chomp
    end


    def __save( outfile, out )
        file = File.new( outfile, 'w' )
        file.write( out )
        file.close
    end

    def __prepare_data( )

        @graph_data = {
            :severities => {
                Issue::Severity::HIGH => 0,
                Issue::Severity::MEDIUM => 0,
                Issue::Severity::LOW => 0,
                Issue::Severity::INFORMATIONAL => 0,
            },
            :issues     => {},
            :elements   => {
                Issue::Element::FORM => 0,
                Issue::Element::LINK => 0,
                Issue::Element::COOKIE => 0,
                Issue::Element::HEADER => 0,
                Issue::Element::BODY => 0,
                Issue::Element::PATH => 0,
                Issue::Element::SERVER => 0,
            },
            :verification => {
                'Yes' => 0,
                'No'  => 0
            }
        }

        @total_severities = 0
        @total_elements   = 0
        @total_verifications = 0

        @crypto_issues = []
        @audit_store.issues.each_with_index {
            |issue, i|

            @crypto_issues << @crypto.encrypt( issue.to_yaml )

            @graph_data[:severities][issue.severity] ||= 0
            @graph_data[:severities][issue.severity] += 1
            @total_severities += 1

            @graph_data[:issues][issue.name] ||= 0
            @graph_data[:issues][issue.name] += 1

            @graph_data[:elements][issue.elem] ||= 0
            @graph_data[:elements][issue.elem] += 1
            @total_elements += 1

            verification = issue.verification ? 'Yes' : 'No'
            @graph_data[:verification][verification] ||= 0
            @graph_data[:verification][verification] += 1
            @total_verifications += 1

            issue.variations.each_with_index {
                |variation, j|

                if( variation['response'] && !variation['response'].empty? )

                    variation['response'] = variation['response'].force_encoding( 'utf-8' )

                    @audit_store.issues[i].variations[j]['escaped_response'] =
                        Base64.encode64( variation['response'] ).gsub( /\n/, '' )
                end

                response = {}
                if !variation['headers']['response'].is_a?( Hash )
                    variation['headers']['response'].split( "\n" ).each {
                        |line|
                        field, value = line.split( ':', 2 )
                        next if !value
                        response[field] = value
                    }
                end
                variation['headers']['response'] = response.dup

            }

        }

        @graph_data[:severities].each {
            |severity, cnt|
            begin
                @graph_data[:severities][severity] = ((cnt/Float(@total_severities)) * 100).to_i
            rescue
                @graph_data[:severities][severity] = 0
            end
        }

        @graph_data[:elements].each {
            |elem, cnt|
            begin
                @graph_data[:elements][elem] = ((cnt/Float(@total_elements)) * 100).to_i
            rescue
                @graph_data[:elements][elem] = 0
            end
        }

        @graph_data[:verification].each {
            |verification, cnt|
            begin
                @graph_data[:verification][verification] = ((cnt/Float(@total_verifications)) * 100).to_i
            rescue
                @graph_data[:verification][verification] = 0
            end
        }

    end

end

end
end
