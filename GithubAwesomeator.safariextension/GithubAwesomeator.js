function lookupElementByXPath(path) { 
    var evaluator = new XPathEvaluator(); 
    var result = evaluator.evaluate(path, document.documentElement, null,XPathResult.FIRST_ORDERED_NODE_TYPE, null); 
    return  result.singleNodeValue; 
} 

function insertAfter(referenceNode, newNode) {
    referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
}

var settings;

var init = function(){
	//var branchPath = "/html/body/div/div[2]/div/div[2]/div/div/div/p/span[2]/span";
	//var repoPath = "/html/body/div/div[2]/div/div/div/h1/strong/a";

	//var repoNode = lookupElementByXPath(repoPath);
	var repoName = document.getElementsByClassName('js-current-repository').item(0).innerHTML;

	//var branchNode = lookupElementByXPath(branchPath);
	var branchName = document.getElementsByClassName('css-truncate-target').item(2).innerHTML;

	//var gitFolder = settings["gitfolder"];

	var commandURL = "github-pr://" + repoName + "/" + branchName;

	var link = document.createElement('a');
	link.setAttribute('href', commandURL);
	link.setAttribute('style', 'float:right');

	var image = document.createElement('img');
	var image_url = settings["baseuri"] + "download_icon_small.png";

	image.setAttribute('src', image_url);
	image.setAttribute('width', '25px');
	image.setAttribute('height', '25px');
	image.setAttribute('style', 'padding:5px 5px 0 0;');

	link.appendChild(image);

	var metaDivPath = "/html/body/div/div[2]/div/div[2]/div/div/div/div";
	var metaDivNode = lookupElementByXPath(metaDivPath);

	metaDivNode.appendChild(link);
	//insertAfter(metaDivNode,link);

}

// listen for an incoming setSettings message
safari.self.addEventListener( "message", function( e ) {
  if( e.name === "setSettings" ) {
    settings = e.message;
    init();
  }
}, false );

// ask proxy.html for settings
safari.self.tab.dispatchMessage( "getSettings" );

