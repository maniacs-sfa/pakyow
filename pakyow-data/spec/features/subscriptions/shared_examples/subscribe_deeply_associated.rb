RSpec.shared_examples :subscription_subscribe_deeply_associated do
  describe "subscribing to a query that includes deeply associated data" do
    class TestHandler
      def initialize(app)
        @app = app
      end

      def call(*); end
    end

    include_context "app"

    let :app_def do
      Pakyow.config.data.default_adapter = :sql
      Pakyow.config.data.subscriptions.adapter = data_subscription_adapter
      Pakyow.config.data.subscriptions.adapter_settings = data_subscription_adapter_settings

      Proc.new do
        Pakyow.after "configure" do
          config.data.connections.sql[:default] = "sqlite::memory"
        end
      end
    end

    let :app_init do
      Proc.new do
        source :posts do
          attribute :title, :string

          has_many :comments
        end

        source :comments do
          attribute :title, :string

          has_many :tags
        end

        source :tags do
          attribute :name, :string
        end

        resource :posts, "/posts" do
          skip :verify_same_origin
          skip :verify_authenticity_token

          collection do
            post "subscribe" do
              data.posts.by_id(1).including(:comments) {
                including(:tags)
              }.subscribe(:post_subscriber, handler: TestHandler)
            end

            post "unsubscribe" do
              data.subscribers.unsubscribe(:post_subscriber)
            end
          end
        end
      end
    end

    before do
      allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:<<) do |_, block|
        block.call
      end

      @post = Pakyow.apps.first.data.posts.create(title: "post").one
      @comment = Pakyow.apps.first.data.comments.create(post: @post, title: "post").one
      Pakyow.apps.first.data.tags.create(comment: @comment, name: "foo")
    end

    after do
      unsubscribe!
    end

    def subscribe!
      response = call("/posts/subscribe", method: :post)
      expect(response[0]).to eq(200)
    end

    def unsubscribe!
      response = call("/posts/unsubscribe", method: :post)
      expect(response[0]).to eq(200)
    end

    it "subscribes" do
      subscribe!
    end
  end
end
