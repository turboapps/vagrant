require 'rexml/document'

module VagrantPlugins
  module Turbo
    module Cap
      module Windows
        class Quota
          def initialize(name, limit, source)
            @__name = name
            @__limit = limit
            @__source = source
          end

          def name
            @__name
          end

          def is_group_policy
            'gpo'.casecmp(@__source) == 0
          end

          def limit
            @__limit
          end
        end

        module WinrmGetQuota
          def self.winrm_get_quota(machine, quota_name)
            output = ''
            machine.communicate.execute('winrm get winrm/config/Winrs -format:xml') do |type, data|
              if type == :stdout
                output << data
              end
            end
            doc = REXML::Document.new(output)
            quota_node = REXML::XPath.first(doc, "//cfg:Winrs/cfg:#{quota_name}")
            if quota_node
              limit = quota_node.text.to_i
              source = quota_node.attribute('Source')
              source_value = if source
                               source.value
                             else
                               ''
                             end
              return Quota.new(quota_name, limit, source_value)
            end
            nil
          end
        end
      end
    end
  end
end
