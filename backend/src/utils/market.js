/**
 * Utility to fetch real-time market data from Yahoo Finance
 */
const fetchStockData = async (tickers) => {
  if (!tickers || tickers.length === 0) return [];
  
  try {
    // Fetch tickers in parallel
    return Promise.all(tickers.map(async (ticker) => {
      try {
        const tickerUrl = `https://query1.finance.yahoo.com/v8/finance/chart/${ticker}?interval=1d&range=1d`;
        const res = await fetch(tickerUrl, {
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36'
          }
        });

        if (!res.ok) {
          console.warn(`Yahoo Finance returned ${res.status} for ${ticker}`);
          return null;
        }

        const stockData = await res.json();
        
        const result = stockData.chart?.result?.[0];
        if (!result) return null;
        
        const meta = result.meta || {};
        const indicators = result.indicators?.quote?.[0] || {};
        const close = indicators.close?.[0] || meta.regularMarketPrice;
        const prevClose = meta.chartPreviousClose;
        
        return {
          ticker: meta.symbol,
          name: meta.longName || meta.symbol,
          price: close,
          change: prevClose ? parseFloat(((close - prevClose) / prevClose * 100).toFixed(2)) : 0,
          volume: indicators.volume?.[0] || meta.regularMarketVolume,
          currency: meta.currency,
          exchange: meta.exchangeName
        };
      } catch (err) {
        console.error(`Error fetching data for ${ticker}:`, err.message);
        return null;
      }
    }));
  } catch (err) {
    console.error('Error in fetchStockData:', err.message);
    return [];
  }
};

module.exports = {
  fetchStockData
};
