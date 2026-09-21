defmodule LiveFrames.BricksResultLifecycleTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Result

  @happy_path [
    :received,
    :recognized,
    :validated,
    :resolved,
    :tree_built,
    :dependencies_extracted,
    :rendered,
    :verified,
    :completed
  ]

  defp diagnostic(code), do: Diagnostic.new(code: code, message: code)

  describe "state collections" do
    test "complete states include active and terminal states without duplicates" do
      states = Result.states()
      active = Result.active_states()
      terminal = Result.terminal_states()

      assert states == active ++ terminal
      assert length(states) == length(Enum.uniq(states))
      assert length(active) == length(Enum.uniq(active))
      assert length(terminal) == length(Enum.uniq(terminal))
      assert states == @happy_path ++ [:rejected, :failed]
    end
  end

  describe "terminal?/1" do
    test "terminal states are true" do
      for state <- Result.terminal_states() do
        assert Result.terminal?(state)
        assert Result.terminal?(Result.new() |> put_status(state))
      end
    end

    test "active states are false" do
      for state <- Result.active_states() do
        refute Result.terminal?(state)
        refute Result.terminal?(Result.new() |> put_status(state))
      end
    end

    test "unknown states are not terminal" do
      refute Result.terminal?(:unknown)
    end
  end

  describe "allowed_transitions/0" do
    test "active states expose happy next plus exceptional targets" do
      allowed = Result.allowed_transitions()

      for state <- Result.active_states() do
        happy_next = Enum.at(@happy_path, Enum.find_index(@happy_path, &(&1 == state)) + 1)
        assert allowed[state] == [happy_next, :rejected, :failed]
      end
    end

    test "terminal states expose no transitions" do
      allowed = Result.allowed_transitions()

      for state <- Result.terminal_states() do
        assert allowed[state] == []
      end
    end
  end

  describe "Result.new/1" do
    test "initializes lifecycle-owned fields" do
      result = Result.new()
      assert result.status == :received
      assert result.lifecycle == [:received]
    end

    test "accepts normal payload fields" do
      result = Result.new(document: %{id: 1}, diagnostics: [diagnostic("existing")])
      assert result.document == %{id: 1}
      assert result.diagnostics == [diagnostic("existing")]
      assert result.status == :received
      assert result.lifecycle == [:received]
    end

    test "rejects status override" do
      assert_raise ArgumentError, ~r/does not accept lifecycle-owned field :status/, fn ->
        Result.new(status: :completed)
      end
    end

    test "rejects lifecycle override" do
      assert_raise ArgumentError, ~r/does not accept lifecycle-owned field :lifecycle/, fn ->
        Result.new(lifecycle: [:received, :completed])
      end
    end
  end

  describe "happy path advance/2" do
    test "walks the complete sequence" do
      result =
        Enum.reduce(Enum.drop(@happy_path, 1), Result.new(), fn next, acc ->
          Result.advance(acc, next)
        end)

      assert result.status == :completed
      assert result.lifecycle == @happy_path
    end

    test "changes only lifecycle-owned fields" do
      payload = [
        document: %{id: "doc"},
        diagnostics: [diagnostic("keep")],
        dependencies: [:dep],
        artifacts: %{"index.html" => "<html></html>"},
        report: %{"ok" => true}
      ]

      result = Result.new(payload)
      advanced = Result.advance(result, :recognized)

      assert advanced.status == :recognized
      assert advanced.lifecycle == [:received, :recognized]
      assert advanced.document == Keyword.get(payload, :document)
      assert advanced.diagnostics == Keyword.get(payload, :diagnostics)
      assert advanced.dependencies == Keyword.get(payload, :dependencies)
      assert advanced.artifacts == Keyword.get(payload, :artifacts)
      assert advanced.report == Keyword.get(payload, :report)
    end
  end

  describe "invalid forward transition" do
    test "rejects skipping a state" do
      result = Result.new() |> Result.advance(:recognized)

      assert_raise ArgumentError, ~r/from recognized to resolved/, fn ->
        Result.advance(result, :resolved)
      end
    end
  end

  describe "skipped transition" do
    test "rejects received to validated" do
      assert_raise ArgumentError, ~r/from received to validated/, fn ->
        Result.advance(Result.new(), :validated)
      end
    end
  end

  describe "completed terminal" do
    setup do
      result = advance_to(:completed, Result.new())
      %{result: result}
    end

    test "rejects completed to rejected", %{result: result} do
      assert_raise ArgumentError, ~r/from completed to rejected/, fn ->
        Result.reject(result, [diagnostic("late")])
      end
    end

    test "rejects completed to failed", %{result: result} do
      assert_raise ArgumentError, ~r/from completed to failed/, fn ->
        Result.fail(result, [diagnostic("late")])
      end
    end

    test "rejects happy-path transition from completed", %{result: result} do
      assert_raise ArgumentError, ~r/from completed to recognized/, fn ->
        Result.advance(result, :recognized)
      end
    end
  end

  describe "rejected terminal" do
    setup do
      result = Result.reject(Result.new(), [diagnostic("reject")])
      %{result: result}
    end

    test "rejects rejected to failed", %{result: result} do
      assert_raise ArgumentError, ~r/from rejected to failed/, fn ->
        Result.fail(result, [diagnostic("too late")])
      end
    end

    test "rejects happy-path transition from rejected", %{result: result} do
      assert_raise ArgumentError, ~r/from rejected to recognized/, fn ->
        Result.advance(result, :recognized)
      end
    end
  end

  describe "failed terminal" do
    setup do
      result = Result.fail(Result.new(), [diagnostic("fail")])
      %{result: result}
    end

    test "rejects failed to rejected", %{result: result} do
      assert_raise ArgumentError, ~r/from failed to rejected/, fn ->
        Result.reject(result, [diagnostic("too late")])
      end
    end

    test "rejects happy-path transition from failed", %{result: result} do
      assert_raise ArgumentError, ~r/from failed to recognized/, fn ->
        Result.advance(result, :recognized)
      end
    end
  end

  describe "explicit forbidden matrix" do
    test "completed to rejected" do
      result = advance_to(:completed, Result.new())

      assert_raise ArgumentError, ~r/from completed to rejected/, fn ->
        Result.reject(result, [])
      end
    end

    test "completed to failed" do
      result = advance_to(:completed, Result.new())

      assert_raise ArgumentError, ~r/from completed to failed/, fn ->
        Result.fail(result, [])
      end
    end

    test "rejected to failed" do
      result = Result.reject(Result.new(), [])

      assert_raise ArgumentError, ~r/from rejected to failed/, fn ->
        Result.fail(result, [])
      end
    end

    test "failed to rejected" do
      result = Result.fail(Result.new(), [])

      assert_raise ArgumentError, ~r/from failed to rejected/, fn ->
        Result.reject(result, [])
      end
    end
  end

  describe "invalid exceptional transition source" do
    test "rejects unknown status to rejected" do
      result = %{Result.new() | status: :corrupted}

      assert_raise ArgumentError, ~r/from corrupted to rejected/, fn ->
        Result.reject(result, [])
      end
    end

    test "rejects unknown status to failed" do
      result = %{Result.new() | status: :corrupted}

      assert_raise ArgumentError, ~r/from corrupted to failed/, fn ->
        Result.fail(result, [])
      end
    end
  end

  describe "active state exceptional transition matrix" do
    test "every active state permits rejected with lifecycle preserved" do
      for state <- Result.active_states() do
        lifecycle = lifecycle_up_to(state)
        result = %{Result.new() | status: state, lifecycle: lifecycle}
        rejected = Result.reject(result, [])

        assert rejected.status == :rejected
        assert rejected.lifecycle == lifecycle ++ [:rejected]
        assert :rejected in Result.allowed_transitions()[state]
      end
    end

    test "every active state permits failed with lifecycle preserved" do
      for state <- Result.active_states() do
        lifecycle = lifecycle_up_to(state)
        result = %{Result.new() | status: state, lifecycle: lifecycle}
        failed = Result.fail(result, [])

        assert failed.status == :failed
        assert failed.lifecycle == lifecycle ++ [:failed]
        assert :failed in Result.allowed_transitions()[state]
      end
    end
  end

  describe "terminal exceptional transition matrix" do
    test "terminal states reject all exceptional transitions" do
      for {state, transition, fun} <- [
            {:completed, :rejected, &Result.reject/2},
            {:completed, :failed, &Result.fail/2},
            {:rejected, :failed, &Result.fail/2},
            {:failed, :rejected, &Result.reject/2}
          ] do
        result = %{Result.new() | status: state, lifecycle: [state]}

        assert_raise ArgumentError, ~r/from #{state} to #{transition}/, fn ->
          fun.(result, [])
        end

        assert Result.allowed_transitions()[state] == []
      end
    end
  end

  describe "reject/2 and fail/2 side effects" do
    test "reject appends diagnostics and rejected lifecycle entry" do
      existing = diagnostic("existing")
      added = diagnostic("added")
      result = Result.new(diagnostics: [existing]) |> Result.reject([added])

      assert result.status == :rejected
      assert result.lifecycle == [:received, :rejected]
      assert result.diagnostics == [existing, added]
    end

    test "fail appends diagnostics and failed lifecycle entry" do
      existing = diagnostic("existing")
      added = diagnostic("added")
      result = Result.new(diagnostics: [existing]) |> Result.fail([added])

      assert result.status == :failed
      assert result.lifecycle == [:received, :failed]
      assert result.diagnostics == [existing, added]
    end

    test "reject preserves unrelated payload fields" do
      payload = [
        document: %{id: "doc"},
        dependencies: [:dep],
        artifacts: %{"index.html" => "<html></html>"},
        report: %{"ok" => true}
      ]

      result = Result.new(payload) |> Result.reject([diagnostic("reject")])

      assert result.document == Keyword.get(payload, :document)
      assert result.dependencies == Keyword.get(payload, :dependencies)
      assert result.artifacts == Keyword.get(payload, :artifacts)
      assert result.report == Keyword.get(payload, :report)
    end

    test "fail preserves unrelated payload fields" do
      payload = [
        document: %{id: "doc"},
        dependencies: [:dep],
        artifacts: %{"index.html" => "<html></html>"},
        report: %{"ok" => true}
      ]

      result = Result.new(payload) |> Result.fail([diagnostic("fail")])

      assert result.document == Keyword.get(payload, :document)
      assert result.dependencies == Keyword.get(payload, :dependencies)
      assert result.artifacts == Keyword.get(payload, :artifacts)
      assert result.report == Keyword.get(payload, :report)
    end
  end

  defp advance_to(:completed, result) do
    Enum.reduce(Enum.drop(@happy_path, 1), result, &Result.advance(&2, &1))
  end

  defp lifecycle_up_to(state) do
    index = Enum.find_index(@happy_path, &(&1 == state))
    Enum.take(@happy_path, index + 1)
  end

  defp put_status(result, status), do: %{result | status: status}
end
