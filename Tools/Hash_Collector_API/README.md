# Cybereason Hash Collector

A professional Python tool for efficiently collecting file hashes from the Cybereason platform and exporting them to CSV format with automatic deduplication.

## 🚀 Features

- **Efficient Hash Collection**: Direct querying of FileHash entities for optimal performance
- **Automatic Deduplication**: Ensures no duplicate hashes in the output
- **Large Dataset Support**: Optimized for collecting millions of hashes
- **Progress Tracking**: Real-time progress monitoring and statistics
- **Resumable Operations**: Batch processing with configurable batch sizes
- **Comprehensive Logging**: Detailed logging for monitoring and debugging
- **Error Handling**: Robust error handling with retry mechanisms
- **Multiple Hash Types**: Support for MD5, SHA1, and SHA256 hashes

## 📋 Requirements

- Python 3.7+
- requests library
- Valid Cybereason platform access credentials

## 🛠️ Installation

1. Clone this repository:
```bash
git clone https://github.com/your-username/cybereason-hash-collector.git
cd cybereason-hash-collector
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure your credentials in the script or use command-line arguments.

## 🔧 Configuration

### Method 1: Edit the script directly
Update the configuration variables at the top of `cybereason_hash_collector.py`:

```python
CYBEREASON_SERVER = "https://your-cybereason-server.com"
CYBEREASON_USERNAME = "your-username"
CYBEREASON_PASSWORD = "your-password"
```

### Method 2: Use command-line arguments
Pass credentials via command-line arguments (recommended for security).

## 📖 Usage

### Basic Usage

```bash
# Basic collection with default settings
python cybereason_hash_collector.py

# Test connection only
python cybereason_hash_collector.py --test-only
```

### Advanced Usage

```bash
# Collect specific number of hashes
python cybereason_hash_collector.py --max-hashes 10000

# Use custom server and credentials
python cybereason_hash_collector.py \
  --server https://your-server.com \
  --username your-username \
  --password your-password

# Large dataset collection (8 million hashes)
python cybereason_hash_collector.py \
  --max-hashes 8000000 \
  --batch-size 5000 \
  --output large_hash_collection.csv

# Verbose logging
python cybereason_hash_collector.py --verbose
```

### Command-Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--server` | Cybereason server URL | From config |
| `--username` | Username for authentication | From config |
| `--password` | Password for authentication | From config |
| `--max-hashes` | Maximum number of hashes to collect | Unlimited |
| `--batch-size` | Batch size for processing | 1000 |
| `--output` | Output CSV file path | Auto-generated |
| `--test-only` | Test connection only | False |
| `--verbose` | Enable verbose logging | False |

## 📊 Output Format

The tool generates CSV files with the following format:

```csv
Hash,Hash_Type,Collection_Date
f60e4b4911c2128fcf397065775fc17d824012d4,SHA1,2025-09-17 10:28:37
2331691adc1f19c2b143dc6e5dff83437c40ce47,SHA1,2025-09-17 10:28:37
...
```

## 🏗️ Architecture

### Collection Methods

1. **Primary Method - Direct FileHash Query**: 
   - Most efficient method
   - Queries FileHash entities directly
   - Supports pagination for large datasets

2. **Fallback Method - Malops Query**:
   - Used when primary method yields few results
   - Queries MalopProcess entities
   - Extracts hashes from imageFile fields

### Performance Optimizations

- **Batch Processing**: Configurable batch sizes for optimal performance
- **Connection Pooling**: Reuses HTTP connections for efficiency
- **Retry Strategy**: Automatic retry for failed requests
- **Memory Efficient**: Processes data in batches to handle large datasets
- **Progress Tracking**: Real-time statistics and progress monitoring

## 📈 Performance

### Typical Performance Metrics

| Dataset Size | Batch Size | Processing Time | Rate |
|--------------|------------|-----------------|------|
| 1,000 hashes | 1,000 | ~30 seconds | ~33 hashes/sec |
| 10,000 hashes | 1,000 | ~5 minutes | ~33 hashes/sec |
| 100,000 hashes | 2,000 | ~50 minutes | ~33 hashes/sec |
| 1,000,000 hashes | 5,000 | ~8 hours | ~35 hashes/sec |
| 8,000,000 hashes | 5,000 | ~65 hours | ~35 hashes/sec |

*Performance may vary based on server response times and network conditions.*

### Optimization Tips for Large Datasets

1. **Increase Batch Size**: For large datasets, use `--batch-size 5000` or higher
2. **Monitor Progress**: Use verbose logging to monitor progress
3. **Resume Capability**: The tool can be restarted if interrupted
4. **Network Optimization**: Ensure stable network connection for large collections

## 🔒 Security Considerations

- **Credentials**: Never commit credentials to version control
- **SSL Verification**: The tool disables SSL verification by default for testing
- **API Access**: Ensure your account has appropriate API access permissions
- **Rate Limiting**: The tool includes built-in retry mechanisms to handle rate limits

## 🐛 Troubleshooting

### Common Issues

1. **Authentication Failed (401)**:
   - Verify username and password
   - Check if account has API access
   - Ensure server URL is correct

2. **Connection Timeout**:
   - Check network connectivity
   - Verify server is accessible
   - Try increasing timeout values

3. **No Hashes Found**:
   - Check if your environment has FileHash data
   - Verify API permissions
   - Try different collection methods

### Debug Mode

Enable verbose logging for detailed debugging:

```bash
python cybereason_hash_collector.py --verbose
```

## 📝 Logging

The tool generates detailed logs in `cybereason_hash_collector.log` including:

- Authentication status
- Collection progress
- Error details
- Performance statistics
- Batch processing information

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This tool is provided as-is for educational and research purposes. Users are responsible for ensuring compliance with their organization's security policies and applicable laws when using this tool.

## 📞 Support

For issues and questions:

1. Check the [troubleshooting section](#-troubleshooting)
2. Review the logs for error details
3. Open an issue on GitHub
4. Contact your Cybereason administrator for API access issues

## 🔄 Version History

- **v2.0.0**: Professional rewrite with large dataset support
- **v1.0.0**: Initial release with basic functionality

---

**Made with ❤️ for the security community**