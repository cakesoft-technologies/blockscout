defmodule BlockScoutWeb.Tokens.OverviewView do
  use BlockScoutWeb, :view

  alias Explorer.Chain.{Address, SmartContract, Token}
  alias Timex

  alias BlockScoutWeb.{CurrencyHelpers, LayoutView}

  @tabs ["token_transfers", "token_holders", "read_contract", "inventory"]
  @etherscan_token_link "https://etherscan.io/token/"
  @blockscout_base_link "https://blockscout.com/"

  def decimals?(%Token{decimals: nil}), do: false
  def decimals?(%Token{decimals: _}), do: true

  def token_name?(%Token{name: nil}), do: false
  def token_name?(%Token{name: _}), do: true

  def total_supply?(%Token{total_supply: nil}), do: false
  def total_supply?(%Token{total_supply: _}), do: true

  def formatted_timestamp(%Token{last_sync: timestamp}) do
    Timex.format!(timestamp, "%b-%d-%Y %H:%M:%S %p %Z", :strftime)
  end

  @doc """
  Get the current tab name/title from the request path and possible tab names.

  The tabs on mobile are represented by a dropdown list, which has a title. This title is the
  currently selected tab name. This function returns that name, properly gettext'ed.

  The list of possible tab names for this page is represented by the attribute @tab.

  Raises error if there is no match, so a developer of a new tab must include it in the list.
  """
  def current_tab_name(request_path) do
    @tabs
    |> Enum.filter(&tab_active?(&1, request_path))
    |> tab_name()
  end

  defp tab_name(["token_transfers"]), do: gettext("Token Transfers")
  defp tab_name(["token_holders"]), do: gettext("Token Holders")
  defp tab_name(["read_contract"]), do: gettext("Read Contract")
  defp tab_name(["inventory"]), do: gettext("Inventory")

  def display_inventory?(%Token{type: "ERC-721"}), do: true
  def display_inventory?(_), do: false

  def smart_contract_with_read_only_functions?(
        %Token{contract_address: %Address{smart_contract: %SmartContract{}}} = token
      ) do
    Enum.any?(token.contract_address.smart_contract.abi, &(&1["constant"] || &1["stateMutability"] == "view"))
  end

  def smart_contract_with_read_only_functions?(%Token{contract_address: %Address{smart_contract: nil}}), do: false

  @doc """
  Get the total value of the token supply in USD.
  """
  def total_supply_usd(token) do
    tokens = CurrencyHelpers.divide_decimals(token.total_supply, token.decimals)
    price = token.usd_value
    Decimal.mult(tokens, price)
  end

  def foreign_bridged_token_explorer_link(token) do
    chain_id = Map.get(token, :foreign_chain_id)

    base_token_explorer_link = get_base_token_explorer_link(chain_id)

    foreign_token_contract_address_hash_string_no_prefix =
      token.foreign_token_contract_address_hash.bytes
      |> Base.encode16(case: :lower)

    foreign_token_contract_address_hash_string = "0x" <> foreign_token_contract_address_hash_string_no_prefix

    base_token_explorer_link <> foreign_token_contract_address_hash_string
  end

  # credo:disable-for-next-line /Complexity/
  defp get_base_token_explorer_link(chain_id) when not is_nil(chain_id) do
    case Decimal.to_integer(chain_id) do
      181 ->
        @blockscout_base_link <> "poa/qdai/tokens/"

      100 ->
        @blockscout_base_link <> "poa/xdai/tokens/"

      99 ->
        @blockscout_base_link <> "poa/core/tokens/"

      77 ->
        @blockscout_base_link <> "poa/sokol/tokens/"

      42 ->
        "https://kovan.etherscan.io/token/"

      3 ->
        "https://ropsten.etherscan.io/token/"

      4 ->
        "https://rinkeby.etherscan.io/token/"

      5 ->
        "https://goerli.etherscan.io/token/"

      1 ->
        @etherscan_token_link

      _ ->
        @etherscan_token_link
    end
  end

  defp get_base_token_explorer_link(_), do: @etherscan_token_link
end
