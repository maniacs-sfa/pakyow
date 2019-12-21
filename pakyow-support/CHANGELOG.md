# v1.1.0 (unreleased)

  * `chg` **Register pipeline actions during initialization.**
    - [Pull Request #365][pr-365]

  * `add` **Introduce `Pipeline::Extension`.**
    - [Pull Request #364][pr-364]

  * `add` **Introduce `Isolable`.**
    - [Pull Request #363][pr-363]

  * `add` **Add a `common_methods` pattern to extensions.**

    *Related links:*
    - [Pull Request #361][pr-361]

  * `add` **Expose `source_location`.**

    *Related links:*
    - [Pull Request #359][pr-359]

  * `add` **Expose `object_name` for makeable, definable objects.**

    *Related links:*
    - [Pull Request #358][pr-358]

  * `add` **Introduce `ObjectName`, `ObjectNamespace`.**

    *Related links:*
    - [Pull Request #357][pr-357]

  * `chg` **Extension restriction violations now raise `RuntimeError`.**

    *Related links:*
    - [Pull Request #352][pr-352]
    - [Commit d410904][d410904]

  * `add` **Add `Extension#include_dependency` and `Extension#extend_dependency`.**

    *Related links:*
    - [Pull Request #352][pr-352]
    - [Commit 3edf137][3edf137]

  * `add` **Introduce `Deprecatable`.**

    *Related links:*
    - [Pull Request #351][pr-351]

  * `add` **Add `Deprecator#ignore`.**
    - Allows deprecations to be ignored during the execution of a block.

    *Related links:*
    - [Pull Request #349][pr-349]

  * `add` **Insulate `Socket`/`IO` from deep freezing.**

    *Related links:*
    - [Pull Request #343][pr-343]
    - [Commit 59e6efe][59e6efe]

  * `add` **Let objects to insulate themselves from a deep freeze.**

    *Related links:*
    - [Pull Request #340][pr-340]

  * `add` **Introduce `Pakyow::Support::Deprecator`**

    *Related links:*
    - [Pull Request #330][pr-330]

  * `chg` **Configure defaults for multiple environments at one time.**
    - `Config` now supports multiple default config blocks per environnment.
    - `Config#defaults` now supports passing multiple environments.

    *Related links:*
    - [Commit 787681d][787681d]

## Deprecations

  * Pipeline extensions should be created with `extend Pakyow::Support::Pipeline::Extension` instead
    of using `extend Pakyow::Support::Pipeline`.

    *Related links:*
    - [Pull Request #364][pr-364]

[pr-365]: https://github.com/pakyow/pakyow/pull/365
[pr-364]: https://github.com/pakyow/pakyow/pull/364
[pr-363]: https://github.com/pakyow/pakyow/pull/363
[pr-361]: https://github.com/pakyow/pakyow/pull/361
[pr-359]: https://github.com/pakyow/pakyow/pull/359
[pr-358]: https://github.com/pakyow/pakyow/pull/358
[pr-357]: https://github.com/pakyow/pakyow/pull/357
[pr-352]: https://github.com/pakyow/pakyow/pull/352
[pr-351]: https://github.com/pakyow/pakyow/pull/351
[pr-349]: https://github.com/pakyow/pakyow/pull/349
[pr-343]: https://github.com/pakyow/pakyow/pull/343
[pr-340]: https://github.com/pakyow/pakyow/pull/340
[pr-330]: https://github.com/pakyow/pakyow/pull/330
[d410904]: https://github.com/pakyow/pakyow/commit/d4109047797e8e5d7f4233fe61a42ed472c96cd7
[3edf137]: https://github.com/pakyow/pakyow/commit/3edf1372869b4a49c4ad83cebc8eb55023f91278
[59e6efe]: https://github.com/pakyow/pakyow/commit/59e6efe42f1d6f5d48d15359d2e1a63bea9a0600
[787681d]: https://github.com/pakyow/pakyow/commit/787681dacbbd3ce79f6e38a5672749635903a85b

# v1.0.2

  * `fix` **Message verification no longer fails when the digest contains `--`.**

    *Related links:*
    - [Pull Request #316][pr-316]

  * `fix` **Avoid including the initializer for configurable modules.**

    *Related links:*
    - [Pull Request #312][pr-312]

  * `fix` **Methods defined an an app block are now defined in the correct context.**

    *Related links:*
    - [Commit 62112dc][62112dc]
    - [Commit f7591d4][f7591d4]

  * `fix` **Named actions can now share a name with a method on the pipelined object.**

    *Related links:*
    - [Pull Request #297][pr-297]
    - [Commit fe1f554][fe1f554]

[pr-316]: https://github.com/pakyow/pakyow/pull/316/commits
[pr-312]: https://github.com/pakyow/pakyow/pull/312/commits
[pr-297]: https://github.com/pakyow/pakyow/pull/297/commits
[f7591d4]: https://github.com/pakyow/pakyow/commit/f7591d406fd87c04eee3ee036da6a780188971b6
[62112dc]: https://github.com/pakyow/pakyow/commit/62112dc1396e397fda73e92df780c4358e28a3fa
[fe1f554]: https://github.com/pakyow/pakyow/commit/fe1f554b56a4c22298f8c2b7809519a9b8eb220b

# v1.0.0

  * Hello, Web
