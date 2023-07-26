defmodule Mix.Tasks.Build.Web do
  @moduledoc """
  Mix task to facilitate frontend compilation
  """

  use Mix.Task
  require Logger

  @public_path "./priv/static/frontend"

  @shortdoc "Compile and bundle React frontend for production"
  def run(_) do
    execute_command!("yarn", [], cd: "./frontend")
    execute_command!("yarn", ["build"], cd: "./frontend")
    execute_command!("rm", ["-rf", @public_path])
    execute_command!("cp", ["-R", "./frontend/dist", @public_path])
  end

  def execute_command!(command, arguments, flags \\ []) do
    # Makes sure command succeeds
    case System.cmd(command, arguments, flags) do
      {_, 0} -> :ok
      {logs, _code} -> raise RuntimeError, message: "Frontend compilation failed:\n" <> logs
    end
  end
end
