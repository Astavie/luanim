mergeInto(LibraryManager.library, {
    print: function(ptr) {
        Module.print(UTF8ToString(ptr));
    }
});
