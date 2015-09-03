path = require 'path'
Package = require '../src/package'
ThemePackage = require '../src/theme-package'

describe "Package", ->
  describe "when the package contains incompatible native modules", ->
    beforeEach ->
      spyOn(atom, 'inDevMode').andReturn(false)

    it "does not activate it", ->
      packagePath = atom.project.getDirectories()[0]?.resolve('packages/package-with-incompatible-native-module')
      pack = new Package(packagePath)
      expect(pack.isCompatible()).toBe false
      expect(pack.incompatibleModules[0].name).toBe 'native-module'
      expect(pack.incompatibleModules[0].path).toBe path.join(packagePath, 'node_modules', 'native-module')

    it "caches the incompatible native modules in local storage", ->
      packagePath = atom.project.getDirectories()[0]?.resolve('packages/package-with-incompatible-native-module')
      cacheKey = null
      cacheItem = null

      spyOn(global.localStorage, 'setItem').andCallFake (key, item) ->
        cacheKey = key
        cacheItem = item
      spyOn(global.localStorage, 'getItem').andCallFake (key) ->
        return cacheItem if cacheKey is key

      expect(new Package(packagePath).isCompatible()).toBe false
      expect(global.localStorage.getItem.callCount).toBe 1
      expect(global.localStorage.setItem.callCount).toBe 1

      expect(new Package(packagePath).isCompatible()).toBe false
      expect(global.localStorage.getItem.callCount).toBe 2
      expect(global.localStorage.setItem.callCount).toBe 1

  describe "theme", ->
    [editorElement, theme] = []

    beforeEach ->
      editorElement = document.createElement('atom-text-editor')
      jasmine.attachToDOM(editorElement)

    afterEach ->
      theme.deactivate() if theme?

    describe "when the theme contains a single style file", ->
      it "loads and applies css", ->
        expect(getComputedStyle(editorElement).paddingBottom).not.toBe "1234px"
        themePath = atom.project.getDirectories()[0]?.resolve('packages/theme-with-index-css')
        theme = new ThemePackage(themePath)
        theme.activate()
        expect(getComputedStyle(editorElement).paddingTop).toBe "1234px"

      it "parses, loads and applies less", ->
        expect(getComputedStyle(editorElement).paddingBottom).not.toBe "1234px"
        themePath = atom.project.getDirectories()[0]?.resolve('packages/theme-with-index-less')
        theme = new ThemePackage(themePath)
        theme.activate()
        expect(getComputedStyle(editorElement).paddingTop).toBe "4321px"

    describe "when the theme contains a package.json file", ->
      it "loads and applies stylesheets from package.json in the correct order", ->
        expect(getComputedStyle(editorElement).paddingTop).not.toBe("101px")
        expect(getComputedStyle(editorElement).paddingRight).not.toBe("102px")
        expect(getComputedStyle(editorElement).paddingBottom).not.toBe("103px")

        themePath = atom.project.getDirectories()[0]?.resolve('packages/theme-with-package-file')
        theme = new ThemePackage(themePath)
        theme.activate()
        expect(getComputedStyle(editorElement).paddingTop).toBe("101px")
        expect(getComputedStyle(editorElement).paddingRight).toBe("102px")
        expect(getComputedStyle(editorElement).paddingBottom).toBe("103px")

    describe "when the theme does not contain a package.json file and is a directory", ->
      it "loads all stylesheet files in the directory", ->
        expect(getComputedStyle(editorElement).paddingTop).not.toBe "10px"
        expect(getComputedStyle(editorElement).paddingRight).not.toBe "20px"
        expect(getComputedStyle(editorElement).paddingBottom).not.toBe "30px"

        themePath = atom.project.getDirectories()[0]?.resolve('packages/theme-without-package-file')
        theme = new ThemePackage(themePath)
        theme.activate()
        expect(getComputedStyle(editorElement).paddingTop).toBe "10px"
        expect(getComputedStyle(editorElement).paddingRight).toBe "20px"
        expect(getComputedStyle(editorElement).paddingBottom).toBe "30px"

    describe "reloading a theme", ->
      beforeEach ->
        themePath = atom.project.getDirectories()[0]?.resolve('packages/theme-with-package-file')
        theme = new ThemePackage(themePath)
        theme.activate()

      it "reloads without readding to the stylesheets list", ->
        expect(theme.getStylesheetPaths().length).toBe 3
        theme.reloadStylesheets()
        expect(theme.getStylesheetPaths().length).toBe 3

    describe "events", ->
      beforeEach ->
        themePath = atom.project.getDirectories()[0]?.resolve('packages/theme-with-package-file')
        theme = new ThemePackage(themePath)
        theme.activate()

      it "deactivated event fires on .deactivate()", ->
        theme.onDidDeactivate spy = jasmine.createSpy()
        theme.deactivate()
        expect(spy).toHaveBeenCalled()

  describe ".loadMetadata()", ->
    [packagePath, pack, metadata] = []

    beforeEach ->
      packagePath = atom.project.getDirectories()[0]?.resolve('packages/package-with-different-directory-name')
      metadata = Package.loadMetadata(packagePath, true)

    it "uses the package name defined in package.json", ->
      expect(metadata.name).toBe 'package-with-a-totally-different-name'
