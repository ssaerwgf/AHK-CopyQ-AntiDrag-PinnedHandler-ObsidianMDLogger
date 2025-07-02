[Command]
Name=Prevent History Duplicates
Automatic=true
Command="
copyq:
if (isClipboard()) {
    var incoming = str(data('text/plain'));
    
    if (incoming) {
        var hasOwnerData = data('application/x-copyq-owner') !== undefined;
        var ownerWindowTitle = str(data('application/x-copyq-owner-window-title'));
        var clipboardMode = str(data('application/x-copyq-clipboard-mode'));
        
        var isFromCopyQ = hasOwnerData || 
                         ownerWindowTitle.indexOf('CopyQ') !== -1 || 
                         clipboardMode.length > 0 ||
                         focused();
        
        if (isFromCopyQ) {
            var itemCount = count();
            
            for (var i = 0; i < itemCount; i++) {
                var existingItem = str(read(i));
                if (existingItem === incoming) {
                    ignore();
                    
                    popup('🛡️ 已阻止重复', '', 500);
                    break;
                }
            }
        }
    }
}
"
Enable=true
Icon=\xf3ed
Input=text/plain