chrome.extension.onMessage.addListener(
  function(request, sender, sendResponse) {
    console.log(sender.tab ?
                "from a content script:" + sender.tab.url :
                "from the extension");
    if (request.message == "getSettings")
      sendResponse({
      	gitfolder: localStorage['gitfolder']
       });
  });