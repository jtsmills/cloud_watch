defmodule CloudWatch.AwsProxy do
  @moduledoc """
    Calls to AWS CloudWatch Logs using one of alternative Elixir client libraries.

    Add either :aws or :ex_aws as a dependency, and correct proxy methods will be chosen.
  """

  cond do
    Code.ensure_loaded?(ExAws) ->
      # AWS CloudWatch Logs implemented using ex_aws
      #  See https://github.com/ex-aws/ex_aws
      #
      # AWS credentials are configured in ExAws (shared with other AWS clients)
      def client(_access_key_id, _secret_access_key, _region, _endpoint) do
        # nothing, we rely on config :ex_aws
        %{}
      end

      def create_log_group(_client, input) do
        request("CreateLogGroup", input)
      end

      def create_log_stream(_client, input) do
        request("CreateLogStream", input)
      end

      def put_log_events(_client, input) do
        request("PutLogEvents", input)
      end

      defp request(action, data) do
        op = %ExAws.Operation.JSON{
          http_method: :post,
          service: :logs,
          headers: [
            {"x-amz-target", "Logs_20140328.#{action}"},
            {"content-type", "application/x-amz-json-1.1"}
          ],
          data: data
        }

        case ExAws.request(op) do
          #      {:ok, {:ok, 200, response_body}} ->
          {:ok, response_body} ->
            {:ok, response_body, response_body}

          {:error, {:http_error, _error_code, %{"__type" => type, "message" => message}}} ->
            {:error, {type, message}}

          {:error, {type, _message, _sequence_token}} = error
          when type in ["DataAlreadyAcceptedException", "InvalidSequenceTokenException"] ->
            error

          {:error, {type, message}} ->
            {:error, {type, message}}
        end
      end

    true ->
      # No AWS library found
      def client(_access_key_id, _secret_access_key, _region, _endpoint) do
        raise ":ex_aws must be added as a dependency to use this module"
      end

      def create_log_group(_client, _input) do
        raise ":ex_aws must be added as a dependency to use this module"
      end

      def create_log_stream(_client, _input) do
        raise ":ex_aws must be added as a dependency to use this module"
      end

      def put_log_events(_client, _input) do
        raise ":ex_aws must be added as a dependency to use this module"
      end
  end
end
