defmodule LiveFrames.BehaviorAuthorityContext do
  @moduledoc false

  @type t :: %__MODULE__{
          behavior_contract: LiveFrames.Behavior.Contract.t(),
          behavior_contract_digest: String.t(),
          selected_behavior_review_result: LiveFrames.Behavior.ReviewResult.t(),
          behavior_review_result_id: String.t()
        }

  defstruct [
    :behavior_contract,
    :behavior_contract_digest,
    :selected_behavior_review_result,
    :behavior_review_result_id
  ]
end
