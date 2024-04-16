# frozen_string_literal: true

module Zoom
  class Utils
    class << self
      def argument_error(name)
        name ? ArgumentError.new("You must provide #{name}") : ArgumentError.new
      end

      def exclude_argument_error(name)
        name ? ArgumentError.new("Unrecognized parameter #{name}") : ArgumentError.new
      end

      def raise_if_error!(response, http_code=200)
        return response unless response.is_a?(Hash) && response.key?('code')

        code = response['code']
        error_message = build_error_message(response)
        error_hash = build_error_hash(response, http_code)

        raise AuthenticationError.new(error_message, error_hash) if code == 124
        raise BadRequest.new(error_message, error_hash) if http_code == 400
        raise Unauthorized.new(error_message, error_hash) if http_code == 401
        raise Forbidden.new(error_message, error_hash) if http_code == 403
        raise NotFound.new(error_message, error_hash) if http_code == 404
        raise Conflict.new(error_message, error_hash) if http_code == 409
        raise TooManyRequests.new(error_message, error_hash) if http_code == 429
        raise InternalServerError.new(error_message, error_hash) if http_code == 500
        raise Error.new(error_message, error_hash)
      end

      def build_error_message(response)
        error_hash = { base: response['message']}
        error_hash[response['message']] = response['errors'] if response['errors']
        error_hash
      end

      def build_error_hash(response, status_code)
        {
          message: response['message'],
          code: response['code'],
          errors: response['errors'],
          http_status_code: status_code
        }.compact
      end

      def parse_response(http_response)
        raise_if_error!(http_response.parsed_response, http_response.code) || http_response.code
      end

      def extract_options!(array)
        params = array.last.is_a?(::Hash) ? array.pop : {}
        process_datetime_params!(params)
      end

      def validate_password(password)
        password_regex = /\A[a-zA-Z0-9@-_*]{0,10}\z/
        raise(Error , 'Invalid Password') unless password[password_regex].nil?
      end

      def process_datetime_params!(params)
        params.each do |key, value|
          case key
          when Symbol, String
            params[key] = value.is_a?(Time) ? value.strftime('%FT%TZ') : value
          when Hash
            process_datetime_params!(params[key])
          end
        end
        params
      end
    end
  end
end
