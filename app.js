const QUEST_SECONDS = 25 * 60;

const timerElement = document.querySelector("#timer");
const progressBar = document.querySelector("#progress-bar");
const toggleButton = document.querySelector("#toggle-button");
const resetButton = document.querySelector("#reset-button");
const completedCountElement = document.querySelector("#completed-count");
const xpCountElement = document.querySelector("#xp-count");

let secondsRemaining = QUEST_SECONDS;
let timerId = null;
let completedCount = Number(localStorage.getItem("focusquest-completed") ?? 0);

function render() {
  const minutes = Math.floor(secondsRemaining / 60);
  const seconds = secondsRemaining % 60;
  const progress = ((QUEST_SECONDS - secondsRemaining) / QUEST_SECONDS) * 100;

  timerElement.textContent = `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  progressBar.style.width = `${progress}%`;
  completedCountElement.textContent = completedCount;
  xpCountElement.textContent = completedCount * 100;
}

function stopTimer() {
  window.clearInterval(timerId);
  timerId = null;
  toggleButton.textContent = "クエスト再開";
}

function completeQuest() {
  stopTimer();
  completedCount += 1;
  localStorage.setItem("focusquest-completed", String(completedCount));
  toggleButton.textContent = "次のクエスト";
  render();
}

function startTimer() {
  if (secondsRemaining === 0) {
    secondsRemaining = QUEST_SECONDS;
  }

  toggleButton.textContent = "一時停止";
  timerId = window.setInterval(() => {
    secondsRemaining -= 1;
    render();

    if (secondsRemaining === 0) {
      completeQuest();
    }
  }, 1000);
}

toggleButton.addEventListener("click", () => {
  if (timerId) {
    stopTimer();
  } else {
    startTimer();
  }
});

resetButton.addEventListener("click", () => {
  window.clearInterval(timerId);
  timerId = null;
  secondsRemaining = QUEST_SECONDS;
  toggleButton.textContent = "クエスト開始";
  render();
});

render();
