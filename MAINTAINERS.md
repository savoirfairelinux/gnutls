# Maintainer Guide: Upgrading GnuTLS Version

This document outlines the standard procedure for maintainers to bump and update this MSVC GnuTLS repository when a new upstream GnuTLS release is published.

---

## 1. Prerequisites and Remotes

Ensure you have remotes configured for both `origin` (this repo) and `upstream` (official GnuTLS repository on GitLab):

```bash
git remote -v
# If missing:
git remote add upstream https://gitlab.com/gnutls/gnutls.git
git fetch upstream --tags
```

Check the latest upstream release tag (e.g. `3.8.x`):
```bash
git tag --list '3.8*' | sort -V | tail -n 10
```

---

## 2. Merging the Upstream Release Tag

Create a merge of the new upstream tag (for instance `3.8.14`):

```bash
git merge --no-commit <TAG>
```

### Resolving Submodule Conflicts

If submodules like `gnulib` or `tests/suite/tls-interoperability` have conflict markers in git, resolve them by taking the upstream commit reference:

```bash
UPSTREAM_COMMIT=$(git ls-tree <TAG> gnulib | awk '{print $3}')
git update-index --cacheinfo 160000 "$UPSTREAM_COMMIT" gnulib

UPSTREAM_TESTS=$(git ls-tree <TAG> tests/suite/tls-interoperability | awk '{print $3}')
if [ -n "$UPSTREAM_TESTS" ]; then
  git update-index --cacheinfo 160000 "$UPSTREAM_TESTS" tests/suite/tls-interoperability
fi
```

Commit the merge:
```bash
git commit -m "Merge tag '<TAG>' into master"
```

---

## 3. Updating Version and Headers

### A. `SMP/version.h`
Update version macros to match the new release:
```c
#define PACKAGE_VERSION "X.Y.Z"
#define VERSION "X.Y.Z"
```

### B. `SMP/gnutls/gnutls.h`
Upstream maintains `lib/includes/gnutls/gnutls.h.in`. Synchronize `SMP/gnutls/gnutls.h` by regenerating from `gnutls.h.in`:
- Replace `@VERSION@` with `X.Y.Z`
- Replace `@MAJOR_VERSION@` with `X`
- Replace `@MINOR_VERSION@` with `Y`
- Replace `@PATCH_VERSION@` with `Z`
- Replace `@NUMBER_VERSION@` with hex value (`0x0X0Y0Z`, e.g., `0x03080e` for `3.8.14`)
- Replace `@DEFINE_IOVEC_T@` with the Windows definition:
  ```c
  typedef struct {
      void *iov_base;
      size_t iov_len;
  } giovec_t;
  ```

---

## 4. Updating Exported Symbols (`SMP/libgnutls.def`)

Inspect newly exported symbols in `lib/libgnutls.map` between the previous version and the new version:
```bash
git diff <OLD_TAG>..<NEW_TAG> -- lib/libgnutls.map
```
Add any new public library functions (`gnutls_*`) into [SMP/libgnutls.def](SMP/libgnutls.def), keeping the file alphabetically sorted under `EXPORTS`.

---

## 5. Updating Visual Studio Project Files

Inspect added or removed files in `lib/`:
```bash
git diff <OLD_TAG>..<NEW_TAG> --name-status lib/ | grep -E '^[AD]'
```

Synchronize the following files:
1. [SMP/libgnutls_files.props](SMP/libgnutls_files.props):
   - Add new headers to `<ClInclude Include="..." />`
   - Add new source files to `<ClCompile Include="..." />`
   - Remove deleted files
2. [SMP/libgnutls.vcxproj.filters](SMP/libgnutls.vcxproj.filters) and [SMP/libgnutls_winrt.vcxproj.filters](SMP/libgnutls_winrt.vcxproj.filters):
   - Mirror additions/removals with appropriate filters (e.g., `Header Files\lib\...`, `Source Files\lib\...`).
3. If new configure defines were added, check [SMP/config.h](SMP/config.h) to enable or undefine them appropriately.

---

## 6. Updating `SMP/SMP.patch`

Regenerate the unified patch capturing all MSVC-specific modifications against the upstream tag:
```bash
git diff <NEW_TAG>..HEAD -- lib/ tests/ gnulib > SMP/SMP.patch
```

---

## 7. Committing and Validating

1. Commit the SMP project changes:
   ```bash
   git add SMP/
   git commit -m "project: Update for X.Y.Z merge"
   ```
2. Push to GitHub and verify that the GitHub Actions CI workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml)) passes across all configurations (Release/Debug, static/DLL, x64/Win32).
3. Create a release tag on GitHub (e.g. `X.Y.Z` or `vX.Y.Z`).
4. Update the vcpkg port in the corresponding vcpkg registry/overlay with the new version and commit SHA.
