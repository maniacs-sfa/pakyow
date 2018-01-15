RSpec.describe "view versioning via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view, embed_templates: false)
  end

  context "when a version is unspecified" do
    context "when there is one unversioned view" do
      let :view do
        Pakyow::Presenter::View.new("<div@post><h1@title></h1></div>")
      end

      it "renders it" do
        expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\"></h1></div>")
      end
    end

    context "when there are multiple views, none of them versioned" do
      let :view do
        Pakyow::Presenter::View.new("<div@post><h1@title>one</h1></div><div@post><h1@title>two</h1></div>")
      end

      it "renders both of them" do
        expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">one</h1></div><div data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
      end
    end

    context "when there are multiple views, one of them being versioned" do
      let :view do
        Pakyow::Presenter::View.new("<div@post><h1@title>one</h1></div><div@post version=\"two\"><h1@title>two</h1></div>")
      end

      it "renders only the first one" do
        expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">one</h1></div>")
      end
    end

    context "when there is only a default version" do
      let :view do
        Pakyow::Presenter::View.new("<div@post version=\"default\"><h1@title>default</h1></div>")
      end

      it "renders the default" do
        expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">default</h1></div>")
      end
    end

    context "when there are multiple versions, including a default" do
      let :view do
        Pakyow::Presenter::View.new("<div@post version=\"one\"><h1@title>one</h1></div><div@post version=\"default\"><h1@title>default</h1></div>")
      end

      it "renders only the default" do
        expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">default</h1></div>")
      end
    end

    context "when there are multiple versions, without a default" do
      let :view do
        Pakyow::Presenter::View.new("<div@post version=\"one\"><h1@title>one</h1></div><div@post version=\"two\"><h1@title>two</h1></div>")
      end

      it "renders neither" do
        expect(presenter.to_s).to eq("")
      end
    end
  end

  context "when rendering without cleaning" do
    context "when a version is unspecified" do
      context "when there is one unversioned view" do
        let :view do
          Pakyow::Presenter::View.new("<div@post><h1@title></h1></div>")
        end

        it "renders it" do
          expect(presenter.to_s(clean: false)).to eq("<div data-s=\"post\"><h1 data-p=\"title\"></h1></div>")
        end
      end

      context "when there are multiple views, none of them versioned" do
        let :view do
          Pakyow::Presenter::View.new("<div@post><h1@title>one</h1></div><div@post><h1@title>two</h1></div>")
        end

        it "renders both of them" do
          expect(presenter.to_s(clean: false)).to eq("<div data-s=\"post\"><h1 data-p=\"title\">one</h1></div><div data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
        end
      end

      context "when there are multiple views, one of them being versioned" do
        let :view do
          Pakyow::Presenter::View.new("<div@post><h1@title>one</h1></div><div@post version=\"two\"><h1@title>two</h1></div>")
        end

        it "renders both of them" do
          expect(presenter.to_s(clean: false)).to eq("<div data-s=\"post\"><h1 data-p=\"title\">one</h1></div><div data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
        end
      end

      context "when there is only a default version" do
        let :view do
          Pakyow::Presenter::View.new("<div@post version=\"default\"><h1@title>default</h1></div>")
        end

        it "renders the default" do
          expect(presenter.to_s(clean: false)).to eq("<div data-s=\"post\"><h1 data-p=\"title\">default</h1></div>")
        end
      end

      context "when there are multiple versions, including a default" do
        let :view do
          Pakyow::Presenter::View.new("<div@post version=\"one\"><h1@title>one</h1></div><div@post version=\"default\"><h1@title>default</h1></div>")
        end

        it "renders all of them" do
          expect(presenter.to_s(clean: false)).to eq("<div data-s=\"post\"><h1 data-p=\"title\">one</h1></div><div data-s=\"post\"><h1 data-p=\"title\">default</h1></div>")
        end
      end

      context "when there are multiple versions, without a default" do
        let :view do
          Pakyow::Presenter::View.new("<div@post version=\"one\"><h1@title>one</h1></div><div@post version=\"two\"><h1@title>two</h1></div>")
        end

        it "renders all of them" do
          expect(presenter.to_s(clean: false)).to eq("<div data-s=\"post\"><h1 data-p=\"title\">one</h1></div><div data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
        end
      end
    end
  end

  context "when a version is used" do
    let :view do
      Pakyow::Presenter::View.new("<div@post version=\"default\"><h1@title>default</h1></div><div@post version=\"two\"><h1@title>two</h1></div>")
    end

    before do
      presenter.find(:post).use(:two)
    end

    it "only renders the used version" do
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
    end

    context "when the used version is missing" do
      before do
        presenter.find(:post).use(:three)
      end

      it "renders nothing" do
        expect(presenter.to_s).to eq("")
      end
    end
  end

  context "when using versioned props inside of an unversioned scope" do
    let :view do
      Pakyow::Presenter::View.new("<div@post><h1@title version=\"default\">default</h1><h1@title version=\"two\">two</h1></div>")
    end

    before do
      presenter.find(:post, :title).use(:two)
    end

    it "renders appropriately" do
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
    end
  end

  context "when using versioned props inside of a versioned scope" do
    let :view do
      Pakyow::Presenter::View.new("<div@post version=\"one\"><h1@title>one</h1></div><div@post version=\"two\"><h1@title version=\"one\">one</h1><h1@title version=\"two\">two</h1></div>")
    end

    before do
      presenter.find(:post).use(:two).find(:title).use(:two)
    end

    it "renders appropriately" do
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
    end
  end

  describe "finding a version" do
    let :view do
      Pakyow::Presenter::View.new("<div@post version=\"default\"><h1@title>default</h1></div><div@post version=\"two\"><h1@title>two</h1></div>")
    end

    let :versioned do
      presenter.find(:post).versioned(:two)
    end

    it "returns the view matching the version" do
      expect(versioned).to be_instance_of(Pakyow::Presenter::View)
      expect(versioned.version).to eq(:two)
      expect(versioned.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
    end

    context "match is not found" do
      it "returns nil" do
        expect(presenter.find(:post).versioned(:nonexistent)).to be(nil)
      end
    end
  end

  describe "presenting a versioned view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post version=\"default\"><h1@title>default</h1></div><div@post version=\"two\"><h1@title>two</h1></div>")
    end

    let :data do
      [{ title: "default" }, { title: "three" }, { title: "two" }]
    end

    it "presents the default version" do
      presenter.find(:post).present(data)
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">default</h1></div><div data-s=\"post\"><h1 data-p=\"title\">three</h1></div><div data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
    end

    context "using versions during presentation" do
      let :view do
        Pakyow::Presenter::View.new("<div@post version=\"default\" title=\"default\"><h1@title>default</h1></div><div@post version=\"two\" title=\"two\"><h1@title>two</h1></div><div@post version=\"three\" title=\"three\"><h1@title>three</h1></div>")
      end

      it "uses a version for each object" do
        presenter.find(:post).present(data) do |view, object|
          view.use(object[:title])
        end

        expect(presenter.to_s).to eq("<div title=\"default\" data-s=\"post\"><h1 data-p=\"title\">default</h1></div><div title=\"three\" data-s=\"post\"><h1 data-p=\"title\">three</h1></div><div title=\"two\" data-s=\"post\"><h1 data-p=\"title\">two</h1></div>")
      end
    end

    context "empty version exists, and data is empty" do
      let :view do
        Pakyow::Presenter::View.new("<div@post version=\"empty\">no posts here</div><div@post><h1@title>post title</h1></div>")
      end

      before do
        presenter.find(:post).present([])
      end

      it "renders the empty version" do
        expect(presenter.to_s).to eq("<div data-p=\"post\">no posts here</div>")
      end
    end
  end
end
