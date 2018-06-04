RSpec.describe "presenting a view that defines an anchor endpoint in a nested binding scope" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new {
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts.including(:comments)
          render "/endpoints/anchor/nested_scope"
        end

        show do
          expose :posts, data.posts.by_id(params[:id].to_i).including(:comments)
          render "/endpoints/anchor/nested_scope"
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.create(params[:post])
        end

        update do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.update(params[:post])
        end

        member do
          get :related, "/related" do
            expose :posts, data.posts
            render "/endpoints/anchor/nested_scope"
          end
        end

        resources :comments, "/comments" do
          disable_protection :csrf

          show do
            # intentionally empty
          end

          create do
            verify do
              required :post_id
              required :comment do
                required :title
              end
            end

            params[:comment][:post_id] = params[:post_id].to_i
            data.comments.create(params[:comment])
          end
        end
      end

      presenter "/endpoints/anchor/nested_scope" do
        find(:post).present(posts)
      end

      source :posts do
        primary_id

        attribute :title

        has_many :comments
      end

      source :comments do
        primary_id

        attribute :title
      end
    }
  end

  context "binding is bound to" do
    it "transforms" do |x|
      expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      expect(call("/posts/1/comments", method: :post, params: { comment: { title: "foo" } })[0]).to eq(200)

      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts/1/comments", method: :post, params: { comment: { title: "bar" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo","comment":[{"id":1,"title":"foo","post_id":1},{"id":2,"title":"bar","post_id":1}]}]],[[["setupEndpoint",[{"name":"posts_show","path":"/posts/1"}],[],[]],["setupEndpoint",[{"name":"posts_comments_show","path":"/posts/comments/1"}],[],[]],["bind",[{"id":1,"title":"foo","comment":[{"id":1,"title":"foo","post_id":1},{"id":2,"title":"bar","post_id":1}]}],[],[]],["find",[["comment"]],[],[["transform",[[{"id":1,"title":"foo"},{"id":2,"title":"bar"}]],[[["setupEndpoint",[{"name":"posts_comments_show","path":"/posts/1/comments/1"}],[],[]],["bind",[{"id":1,"title":"foo"}],[],[]]],[["setupEndpoint",[{"name":"posts_comments_show","path":"/posts/1/comments/2"}],[],[]],["bind",[{"id":2,"title":"bar"}],[],[]]]],[]]]]]],[]]]]]'
      )
    end

    context "endpoint is current" do
      it "transforms" do |x|
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)

        transformations = save_ui_case(x, path: "/posts/1") do
          expect(call("/posts/1", method: :patch, params: { post: { title: "bar" } })[0]).to eq(200)
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"bar","comment":[]}]],[[["setupEndpoint",[{"name":"posts_show","path":"/posts/1"}],[],[]],["setupEndpoint",[{"name":"posts_comments_show","path":"/posts/comments/1"}],[],[]],["bind",[{"id":1,"title":"bar","comment":[]}],[],[]],["find",[["comment"]],[],[["remove",[],[],[]],["transform",[[]],[],[]]]]]],[]]]]]'
        )
      end
    end

    context "endpoint matches the first part of current" do
      it "transforms" do |x|
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)

        transformations = save_ui_case(x, path: "/posts/1/related") do
          expect(call("/posts", method: :post, params: { post: { title: "bar" } })[0]).to eq(200)
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo"},{"id":2,"title":"bar"}]],[[["setupEndpoint",[{"name":"posts_show","path":"/posts/1"}],[],[]],["setupEndpoint",[{"name":"posts_comments_show","path":"/posts/comments/1"}],[],[]],["bind",[{"id":1,"title":"foo"}],[],[]],["find",[["comment"]],[],[["remove",[],[],[]]]]],[["setupEndpoint",[{"name":"posts_show","path":"/posts/2"}],[],[]],["setupEndpoint",[{"name":"posts_comments_show","path":"/posts/comments/2"}],[],[]],["bind",[{"id":2,"title":"bar"}],[],[]],["find",[["comment"]],[],[["remove",[],[],[]]]]]],[]]]]]'
        )
      end
    end
  end
end
