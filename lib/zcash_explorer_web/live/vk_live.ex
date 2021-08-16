defmodule ZcashExplorerWeb.VkLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""

    <div class="text-green-400 font-mono break-all ">
    <%= @message["message"] %>
    </div>

    <%= if length(@message["txs"]) > 0  do %>
    <div class="shadow overflow-hidden border-b border-gray-200 rounded-lg overflow-x-auto">
    <table class="min-w-full divide-y divide-gray-200">
      <thead class="bg-gray-50">
      <tr>
         <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-midnight-500 uppercase tracking-wider">Tx</th>
         <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-midnight-500 uppercase tracking-wider">Amount</th>
          <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-midnight-500 uppercase tracking-wider">Address</th>
          <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-midnight-500 uppercase tracking-wider">Date</th>
          <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-midnight-500 uppercase tracking-wider">Memo</th>
        </tr>
       </thead>
      <tbody class="bg-white-500 divide-y divide-gray-200">

    <%= for tx <- @message["txs"] do %>
    <tr class="hover:bg-indigo-50">
     <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-indigo-600 hover:text-indigo-500">
        <a href='/transactions/<%= tx["txid"] %>' target="_blank">
        <%= tx["txid"] %>
        </a>
    </td>
    <td class="px-4 py-4 whitespace-nowrap text-sm font-medium text-gray-500">
        <%= ZcashExplorerWeb.AddressView.zatoshi_to_zec(tx["amount"]) %>
    </td>
    <td class="px-4 py-4 whitespace-nowrap text-sm font-medium text-gray-500">
        <%= tx["address"] %>
    </td>
    <td class="px-4 py-4 whitespace-nowrap text-sm font-medium text-gray-500">
        <%= ZcashExplorerWeb.BlockView.mined_time_rel(tx["datetime"]) %>
    </td>    
    <td class="px-4 py-4 whitespace-nowrap text-sm font-medium text-gray-500 break-all">
        <%= tx["memo"] %>
    </td> 
           </tr>        
    <% end %>

     </tbody>
    </table>
    <% end %>



    """
  end

  def mount(params, session, socket) do
    if connected?(socket) do
      container_id = Map.get(session, "container_id")
      Process.send_after(self(), :update, 3000)
      subscribed = Phoenix.PubSub.subscribe(ZcashExplorer.PubSub, "VK:" <> "#{container_id}")
    end

    {:ok,
     assign(socket, :message, %{
       "message" => "Starting to import the VK .",
       "container_id" => Map.get(session, "container_id"),
       "txs" => []
     })}
  end

  def handle_info(:update, socket) do
    if length(socket.assigns.message["txs"]) == 0 do
      Process.send_after(self(), :update, 3000)
    end

    cmd = MuonTrap.cmd("docker", ["logs", socket.assigns.message["container_id"]])
    logs = elem(cmd, 0) |> Phoenix.HTML.Format.text_to_html()

    {:noreply,
     assign(socket, :message, %{
       "message" => logs,
       "container_id" => socket.assigns.message["container_id"],
       "txs" => socket.assigns.message["txs"]
     })}
  end

  def handle_info({:received_txs, txs}, socket) do
    {:noreply,
     assign(socket, :message, %{
       "message" => "Got list of txs",
       "container_id" => socket.assigns.message["container_id"],
       "txs" => txs
     })}
  end
end