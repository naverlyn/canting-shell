.pragma library

function getWeatherIcon(cond, isNight) {
    var c = (cond || "").toLowerCase();
    if (c.indexOf("thunder") !== -1 || c.indexOf("storm") !== -1 || c.indexOf("lightning") !== -1) return "󰙾";
    if (c.indexOf("snow") !== -1 || c.indexOf("sleet") !== -1 || c.indexOf("blizzard") !== -1 || c.indexOf("ice") !== -1) return "󰖘";
    if (c.indexOf("heavy rain") !== -1 || c.indexOf("torrential") !== -1 || c.indexOf("downpour") !== -1) return "󰖖";
    if (c.indexOf("rain") !== -1 || c.indexOf("drizzle") !== -1 || c.indexOf("shower") !== -1) return "󰖗";
    if (c.indexOf("fog") !== -1 || c.indexOf("mist") !== -1 || c.indexOf("haze") !== -1 || c.indexOf("smog") !== -1) return "󰖑";
    if (c.indexOf("overcast") !== -1 || c.indexOf("cloudy") !== -1) return "󰖐";
    if (c.indexOf("partly") !== -1) return isNight ? "󰼱" : "󰖕";
    if (c.indexOf("clear") !== -1 || c.indexOf("sunny") !== -1) return isNight ? "󰖔" : "󰖙";
    return isNight ? "󰖔" : "󰖙";
}

function formatDayLabel(dateStr, index) {
    if (index === 0) return "Today";
    if (index === 1) return "Tomorrow";
    try {
        var parts = dateStr.split("-");
        var d = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return days[d.getDay()] + " " + d.getDate();
    } catch (e) {
        return dateStr;
    }
}

function formatFullDate(dateStr, index) {
    try {
        var parts = dateStr.split("-");
        var d = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var prefix = index === 0 ? "Today · " : (index === 1 ? "Tomorrow · " : "");
        return prefix + days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()];
    } catch (e) {
        return dateStr;
    }
}

function parseWeatherData(popup, data, isImp) {
    if (!data || !data.current_condition || data.current_condition.length === 0) {
        return;
    }
    var curr = data.current_condition[0];
    popup.conditionText = (curr.weatherDesc && curr.weatherDesc[0]) ? curr.weatherDesc[0].value.trim() : "Unknown";
    popup.tempText = (isImp ? curr.temp_F : curr.temp_C) + "°" + (isImp ? "F" : "C");
    popup.feelsLikeText = (isImp ? curr.FeelsLikeF : curr.FeelsLikeC) + "°" + (isImp ? "F" : "C");
    popup.humidityText = (curr.humidity || "0") + "%";
    popup.windText = (isImp ? (curr.windspeedMiles + " mph") : (curr.windspeedKmph + " km/h")) + (curr.winddir16Point ? (" " + curr.winddir16Point) : "");
    popup.precipText = (isImp ? (curr.precipInches + " in") : (curr.precipMM + " mm"));
    popup.uvText = curr.uvIndex ? ("UV " + curr.uvIndex) : "UV 0";
    popup.pressureText = isImp ? (curr.pressureInches + " inHg") : (curr.pressure + " hPa");

    if (data.weather && data.weather.length > 0 && data.weather[0].astronomy && data.weather[0].astronomy[0]) {
        var a = data.weather[0].astronomy[0];
        popup.sunriseText = a.sunrise || "--";
        popup.sunsetText = a.sunset || "--";
        popup.moonPhaseText = a.moon_phase || "";
    }

    var daysList = [];
    var rawDays = data.weather || [];
    var targetTimes = [
        { key: "900", name: "Morning", icon: "󰖚", isNight: false },
        { key: "1200", name: "Noon", icon: "󰖙", isNight: false },
        { key: "1800", name: "Evening", icon: "󰖛", isNight: false },
        { key: "2100", name: "Night", icon: "󰖔", isNight: true }
    ];

    for (var i = 0; i < rawDays.length; i++) {
        var d = rawDays[i];
        var dateStr = d.date || "";
        var maxT = (isImp ? d.maxtempF : d.maxtempC) + "°";
        var minT = (isImp ? d.mintempF : d.mintempC) + "°";

        var slots = [];
        var hourly = d.hourly || [];

        for (var j = 0; j < targetTimes.length; j++) {
            var target = targetTimes[j];
            var match = null;
            for (var k = 0; k < hourly.length; k++) {
                if (hourly[k].time === target.key) {
                    match = hourly[k];
                    break;
                }
            }
            if (!match && hourly.length > j) {
                match = hourly[j];
            }
            if (match) {
                var cDesc = (match.weatherDesc && match.weatherDesc[0]) ? match.weatherDesc[0].value.trim() : "";
                slots.push({
                    name: target.name,
                    timeIcon: target.icon,
                    condition: cDesc,
                    weatherIcon: getWeatherIcon(cDesc, target.isNight),
                    temp: (isImp ? match.tempF : match.tempC) + "°",
                    feels: (isImp ? match.FeelsLikeF : match.FeelsLikeC) + "°",
                    rain: (match.chanceofrain || "0") + "%",
                    wind: (isImp ? (match.windspeedMiles + " mph") : (match.windspeedKmph + " km/h")),
                    isNight: target.isNight
                });
            }
        }

        var dayCond = slots.length > 1 ? slots[1].condition : (slots.length > 0 ? slots[0].condition : "");

        daysList.push({
            date: dateStr,
            tabLabel: formatDayLabel(dateStr, i),
            fullDateLabel: formatFullDate(dateStr, i),
            maxTemp: maxT,
            minTemp: minT,
            condition: dayCond,
            conditionIcon: getWeatherIcon(dayCond, false),
            slots: slots
        });
    }

    popup.forecastDays = daysList;
    popup.hasValidData = true;
}
