const Briefing = require('./briefing.model');
const BriefingConfig = require('./briefing_config.model');

class BriefingService {
  /**
   * Get the most recent briefing
   */
  async getLatest() {
    const briefing = await Briefing.findOne().sort({ createdAt: -1 });
    const config = await BriefingConfig.findOne();

    if (!briefing) {
      console.log('BriefingService: No latest briefing found in database.');
      return null;
    }

    console.log(`BriefingService: Found latest briefing from ${briefing.createdAt}`);

    let briefingData = briefing.data;

    // If data is a string (common from n8n), try to parse it if we need to filter
    if (typeof briefingData === 'string') {
      try {
        briefingData = JSON.parse(briefingData);
        console.log('BriefingService: Parsed briefing data string into object.');
      } catch (e) {
        console.error('BriefingService: Failed to parse briefing data string:', e.message);
        // Keep it as string if parsing fails, filtering will be skipped
      }
    }

    // Filter briefing data based on enabled topics if it's an object/map
    if (config && config.topics && typeof briefingData === 'object' && briefingData !== null && !Array.isArray(briefingData)) {
      console.log('BriefingService: Filtering briefing data. Total categories found:', Object.keys(briefingData).length);
      const filteredData = {};
      
      const disabledTopicNames = config.topics
        .filter(t => !t.enabled)
        .map(t => t.name);
      
      console.log('BriefingService: Disabled topics:', disabledTopicNames);

      Object.keys(briefingData).forEach(categoryName => {
        if (!disabledTopicNames.includes(categoryName)) {
          filteredData[categoryName] = briefingData[categoryName];
        } else {
          console.log(`BriefingService: Category "${categoryName}" is disabled and filtered out.`);
        }
      });
      briefingData = filteredData;
      console.log(`BriefingService: Final filtered briefing count: ${Object.keys(briefingData).length}`);
    } 
    else if (config && config.topics && Array.isArray(briefingData)) {
      // Handle array format if it ever appears
      briefingData = briefingData.filter(category => {
        const categoryName = Object.keys(category)[0];
        const enabledTopic = config.topics.find(t => t.name === categoryName);
        return enabledTopic ? enabledTopic.enabled : false;
      });
    }

    return {
      _id: briefing._id,
      data: briefingData,
      source: briefing.source,
      createdAt: briefing.createdAt,
      updatedAt: briefing.updatedAt,
    };
  }

  /**
   * Save a new briefing
   * @param {Object} data - The briefing data received from agents/n8n
   */
  async save(data) {
    // If the data is wrapped in another object (common from n8n), extract it
    const cleanData = data.data || data;
    
    const briefing = new Briefing({
      data: cleanData,
      source: 'n8n',
    });

    return await briefing.save();
  }

  /**
   * Update the global briefing configuration (topics/tickers)
   * @param {Object} data - { topics: Array, tickers: Array }
   */
  async updateConfig(data) {
    console.log('BriefingService: Updating config with data:', JSON.stringify(data, null, 2));
    const cleanData = data.data || data;
    const { topics: newTopics, tickers } = cleanData;

    let config = await BriefingConfig.findOne();
    if (!config) {
      console.log('BriefingService: No existing config found, creating new one.');
      config = new BriefingConfig();
    }

    if (newTopics && Array.isArray(newTopics)) {
      console.log(`BriefingService: Updating ${newTopics.length} topics.`);
      
      // Clear existing topics and rebuild to ensure order and state match exactly
      // Mongoose subdocument arrays are better managed by clearing and re-adding 
      // if the entire state is sent from the frontend.
      config.topics = [];
      for (const newTopic of newTopics) {
        if (newTopic && newTopic.name) {
          config.topics.push({ 
            name: newTopic.name, 
            enabled: typeof newTopic.enabled === 'boolean' ? newTopic.enabled : true 
          });
        }
      }
    }
    
    if (tickers) {
      console.log(`BriefingService: Updating ${tickers.length} tickers.`);
      config.tickers = tickers;
    }

    const savedConfig = await config.save();
    console.log('BriefingService: Config saved successfully.');
    return savedConfig;
  }

  /**
   * Toggle the enabled status of a specific topic.
   * @param {string} topicName - The name of the topic to toggle.
   * @param {boolean} enabled - The desired enabled status.
   */
  async toggleTopic(topicName, enabled) {
    let config = await BriefingConfig.findOne();
    if (!config) {
      // If no config exists, create one with default topics and the specified topic toggled
      config = new BriefingConfig();
      const topicToToggle = config.topics.find(t => t.name === topicName);
      if (topicToToggle) {
        topicToToggle.enabled = enabled;
      } else {
        config.topics.push({ name: topicName, enabled: enabled });
      }
    } else {
      const topic = config.topics.find(t => t.name === topicName);
      if (topic) {
        topic.enabled = enabled;
      } else {
        // If topic doesn't exist, add it.
        config.topics.push({ name: topicName, enabled: enabled });
      }
    }
    return await config.save();
  }

  /**
   * Get the global briefing configuration
   */
  async getConfig() {
    return await BriefingConfig.findOne();
  }

  /**
   * Get historical briefings (paginated)
   * @param {number} page
   * @param {number} limit
   */
  async getHistory(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    
    const [briefings, total] = await Promise.all([
      Briefing.find().sort({ createdAt: -1 }).skip(skip).limit(limit),
      Briefing.countDocuments(),
    ]);

    return {
      briefings,
      total,
      page,
      limit,
    };
  }
}

module.exports = new BriefingService();
