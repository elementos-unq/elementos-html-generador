
window.onload = ()->
  currentExample = document.querySelector '#currentExample'  
  contentOutput = document.querySelector '#contentOutput'  
  shadow = document.querySelector '#shadow'  
  window.process_content = ()->
    shadow.classList.add "remove"
    contentOutput.innerHTML = currentExample.value
  