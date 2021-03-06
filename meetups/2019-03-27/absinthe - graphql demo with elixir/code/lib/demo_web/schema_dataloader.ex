defmodule DemoWeb.Schema do
  use Absinthe.Schema
  import Absinthe.Resolution.Helpers
  alias Demo.Meetups.Meetup
  alias Demo.Meetups

  import_types(Absinthe.Plug.Types)


  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  def dataloader() do

    Dataloader.new()
    |> Dataloader.add_source(Meetups, Meetups.data())
  end

  def context(ctx) do
    Map.put(ctx, :loader, dataloader())
  end

  @desc "City"
  object :city do
    @desc "Unique Id"
    field(:id, non_null(:id))

    @desc "City name ex. Wroclaw"
    field(:name, non_null(:string))

    @desc "Meetups in given city"
    field :meetups, non_null(list_of(non_null(:meetup))) do
      resolve(dataloader(Meetups, :meetups))
    end
  end


  @desc "Meetup"
  object :meetup do
    @desc "Unique Id"
    field(:id, non_null(:id))

    @desc "Short meetup name"
    field(:name, non_null(:string))

    @desc "Meetup description"
    field(:description, non_null(:string))

    @desc "Meetup location"
    field(:location, non_null(:string))

    @desc "Number of likes meetup received"
    field(:likes, non_null(:integer))

    @desc "Speakers giving talks"
    field :speakers, non_null(list_of(non_null(:speaker))) do
      resolve(dataloader(Meetups, :speakers))
    end
  end

  @desc "Speaker"
  object :speaker do
    @desc "Unique Id"
    field(:id, non_null(:id))

    @desc "Speaker first and last name"
    field(:name, non_null(:string))

    @desc "Title of the talk"
    field(:title, non_null(:string))
  end


  query do
    field :cities, non_null(list_of(non_null(:city))) do
      resolve fn _, _, _ ->
        {:ok, Meetups.list_cities()}
      end
    end

    field :city, :city do
      arg :city_id, non_null(:id)

      resolve fn _, %{city_id: city_id}, _ ->
        {:ok, Meetups.get_city_by_id(city_id)}
      end
    end
  end

  mutation do
    @desc "Increases meetup likes count"
    field :like_meetup, :meetup do
      @desc "Meetup ID"
      arg(:meetup_id, non_null(:id))

      resolve fn _, %{meetup_id: meetup_id}, _ ->
        with %Meetup{} = meetup <- Meetups.get_by_id(meetup_id) do
          Meetups.like(meetup)
        end
      end
    end
  end

  subscription do
    field :new_like, non_null(:meetup) do
      arg :meetup_id, non_null(:id)

      config(fn args, _ ->
        {:ok, topic: args.meetup_id}
      end)

      trigger [:like_meetup], topic: fn
        %{id: id} -> [id]
        _ -> []
        end
    end
  end
end
