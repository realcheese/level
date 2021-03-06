defmodule LevelWeb.GraphQL.OpenInvitationTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Repo

  @query """
    query OpenInvitationURL(
      $space_id: ID!
    ) {
      spaceUser(spaceId: $space_id) {
        space {
          openInvitationUrl
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, open_invitation: open_invitation}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, space: space, open_invitation: open_invitation}}
  end

  test "space payload includes the active open invitation URL", %{
    conn: conn,
    space: space,
    open_invitation: open_invitation
  } do
    variables = %{space_id: space.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "spaceUser" => %{
                 "space" => %{
                   "openInvitationUrl" =>
                     "http://level.test:4001/invites/#{open_invitation.token}"
                 }
               }
             }
           }
  end

  test "space payload includes nil open invitation URL if disabled", %{
    conn: conn,
    space: space,
    open_invitation: open_invitation
  } do
    open_invitation
    |> Ecto.Changeset.change(state: "REVOKED")
    |> Repo.update()

    variables = %{space_id: space.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "spaceUser" => %{
                 "space" => %{
                   "openInvitationUrl" => nil
                 }
               }
             }
           }
  end
end
