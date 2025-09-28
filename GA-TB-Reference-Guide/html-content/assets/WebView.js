function WKWebView_HighlightAllOccurencesOfStringForElement(element, keyword) {
    if (element) {
        if (element.nodeType == 3) {        // Text node
            while (true) {
                var value = element.nodeValue;  // Search for keyword in text node
                var idx = value.toLowerCase().indexOf(keyword);
                
                if (idx < 0) break;             // not found, abort
                
                var span = document.createElement("span");
                var text = document.createTextNode(value.substr(idx, keyword.length));
                span.appendChild(text);
                span.setAttribute("class", "WKWebView_Highlight");
                span.style.backgroundColor = "#FFBE0C";
                span.style.color = "black";
                text = document.createTextNode(value.substr(idx + keyword.length));
                element.deleteData(idx, value.length - idx);
                var next = element.nextSibling;
                element.parentNode.insertBefore(span, next);
                element.parentNode.insertBefore(text, next);
                element = text;
            }
        } else if (element.nodeType == 1) { // Element node
            if (element.style.display != "none" && element.nodeName.toLowerCase() != 'select') {
                for (var i = element.childNodes.length - 1; i >= 0; i--) {
                    WKWebView_HighlightAllOccurencesOfStringForElement(element.childNodes[i], keyword);
                }
            }
        }
    }
}

function WKWebView_RemoveAllHighlightsForElement(element) {
    if (element) {
        if (element.nodeType == 1) {
            if (element.getAttribute("class") == "WKWebView_Highlight") {
                var text = element.removeChild(element.firstChild);
                element.parentNode.insertBefore(text, element);
                element.parentNode.removeChild(element);
                return true;
            } else {
                var normalize = false;
                for (var i = element.childNodes.length - 1; i >= 0; i--) {
                    if (WKWebView_RemoveAllHighlightsForElement(element.childNodes[i])) {
                        normalize = true;
                    }
                }
                if (normalize) {
                    element.normalize();
                }
            }
        }
    }
    return false;
}

function WKWebView_RemoveAllHighlights() {
    WKWebView_RemoveAllHighlightsForElement(document.body);
    // Also reset navigation state when removing highlights
    WKWebView_SearchResults = [];
    WKWebView_CurrentIndex = -1;
    WKWebView_CurrentKeyword = "";
}

function WKWebView_HighlightAllOccurencesOfString(keyword, first) {
    if (first) {
        WKWebView_RemoveAllHighlights();
    }
    WKWebView_HighlightAllOccurencesOfStringForElement(document.body, keyword.toLowerCase());
}

// NEW NAVIGATION FUNCTIONALITY
// Global variables to track search state for navigation
var WKWebView_SearchResults = [];
var WKWebView_CurrentIndex = -1;
var WKWebView_CurrentKeyword = "";

// Enhanced function for navigable highlighting
function WKWebView_HighlightAllOccurencesOfStringForElementWithNavigation(element, keyword, isActive) {
    if (element) {
        if (element.nodeType == 3) {        // Text node
            while (true) {
                var value = element.nodeValue;  // Search for keyword in text node
                var idx = value.toLowerCase().indexOf(keyword);
                
                if (idx < 0) break;             // not found, abort
                
                var span = document.createElement("span");
                var text = document.createTextNode(value.substr(idx, keyword.length));
                span.appendChild(text);
                span.setAttribute("class", "WKWebView_Highlight");
                span.setAttribute("data-search-index", WKWebView_SearchResults.length);
                
                // Different styling for active vs inactive highlights
                if (isActive) {
                    span.style.backgroundColor = "#FF6B35"; // Orange for active
                    span.style.color = "white";
                    span.style.fontWeight = "bold";
                } else {
                    span.style.backgroundColor = "#FFBE0C"; // Yellow for inactive
                    span.style.color = "black";
                }
                
                span.style.borderRadius = "2px";
                span.style.padding = "1px 2px";
                
                // Store reference for navigation
                WKWebView_SearchResults.push(span);
                
                text = document.createTextNode(value.substr(idx + keyword.length));
                element.deleteData(idx, value.length - idx);
                var next = element.nextSibling;
                element.parentNode.insertBefore(span, next);
                element.parentNode.insertBefore(text, next);
                element = text;
            }
        } else if (element.nodeType == 1) { // Element node
            if (element.style.display != "none" && element.nodeName.toLowerCase() != 'select') {
                for (var i = element.childNodes.length - 1; i >= 0; i--) {
                    WKWebView_HighlightAllOccurencesOfStringForElementWithNavigation(element.childNodes[i], keyword, isActive);
                }
            }
        }
    }
}

// New function for navigable search highlighting
function WKWebView_HighlightAllOccurencesOfStringWithNavigation(keyword, first) {
    if (first) {
        WKWebView_RemoveAllHighlights();
    }
    
    WKWebView_CurrentKeyword = keyword.toLowerCase();
    WKWebView_HighlightAllOccurencesOfStringForElementWithNavigation(document.body, WKWebView_CurrentKeyword, false);
    
    // If we have results and no current selection, select the first one
    if (WKWebView_SearchResults.length > 0 && WKWebView_CurrentIndex === -1) {
        WKWebView_GoToSearchResult(0);
    }
    
    return WKWebView_SearchResults.length;
}

function WKWebView_UpdateHighlightStyles() {
    // Reset all highlights to inactive style
    for (var i = 0; i < WKWebView_SearchResults.length; i++) {
        var span = WKWebView_SearchResults[i];
        if (span && span.parentNode) {
            span.style.backgroundColor = "#FFBE0C"; // Yellow for inactive
            span.style.color = "black";
            span.style.fontWeight = "normal";
        }
    }
    
    // Highlight the current active result
    if (WKWebView_CurrentIndex >= 0 && WKWebView_CurrentIndex < WKWebView_SearchResults.length) {
        var activeSpan = WKWebView_SearchResults[WKWebView_CurrentIndex];
        if (activeSpan && activeSpan.parentNode) {
            activeSpan.style.backgroundColor = "#FF6B35"; // Orange for active
            activeSpan.style.color = "white";
            activeSpan.style.fontWeight = "bold";
        }
    }
}

function WKWebView_GoToSearchResult(index) {
    if (WKWebView_SearchResults.length === 0) return false;
    
    // Clamp index to valid range
    index = Math.max(0, Math.min(index, WKWebView_SearchResults.length - 1));
    WKWebView_CurrentIndex = index;
    
    // Update highlight styles
    WKWebView_UpdateHighlightStyles();
    
    // Scroll to the active result
    var activeSpan = WKWebView_SearchResults[WKWebView_CurrentIndex];
    if (activeSpan && activeSpan.parentNode) {
        activeSpan.scrollIntoView({
            behavior: 'smooth',
            block: 'center',
            inline: 'nearest'
        });
    }
    
    return true;
}

function WKWebView_GoToNextSearchResult() {
    if (WKWebView_SearchResults.length === 0) return false;
    
    var nextIndex = WKWebView_CurrentIndex + 1;
    if (nextIndex >= WKWebView_SearchResults.length) {
        nextIndex = 0; // Wrap around to first result
    }
    
    return WKWebView_GoToSearchResult(nextIndex);
}

function WKWebView_GoToPreviousSearchResult() {
    if (WKWebView_SearchResults.length === 0) return false;
    
    var prevIndex = WKWebView_CurrentIndex - 1;
    if (prevIndex < 0) {
        prevIndex = WKWebView_SearchResults.length - 1; // Wrap around to last result
    }
    
    return WKWebView_GoToSearchResult(prevIndex);
}

function WKWebView_GetSearchInfo() {
    return {
        totalResults: WKWebView_SearchResults.length,
        currentIndex: WKWebView_CurrentIndex,
        currentPosition: WKWebView_CurrentIndex + 1, // 1-based for display
        keyword: WKWebView_CurrentKeyword
    };
}
