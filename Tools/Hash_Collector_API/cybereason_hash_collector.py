#!/usr/bin/env python3
"""
Cybereason Hash Collector

A professional tool for collecting file hashes from the Cybereason platform
and exporting them to CSV format with deduplication.

Features:
- Efficient hash collection from multiple Cybereason data sources
- Automatic deduplication of hashes
- Progress tracking and resumable operations
- Configurable batch sizes for large datasets
- Comprehensive logging and error handling
- Support for millions of hashes

Author: Or Cohen
License: MIT
Version: 2.0.0
"""

import argparse
import csv
import logging
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


# Configuration - Update these with your Cybereason credentials
# NOTE: You may need an API-specific user account, not a regular GUI user
CYBEREASON_SERVER = "https://XXXXXX.cybereason.net"
CYBEREASON_USERNAME = "XXXXX@cybereason.com"  # Try API-specific username if available
CYBEREASON_PASSWORD = r"XXXXXXXXXXXXX"  # Try API-specific password if available


class CybereasonHashCollector:
    """
    Professional hash collector for Cybereason platform.
    
    This class provides efficient methods to collect file hashes from various
    Cybereason data sources with support for large datasets and progress tracking.
    """
    
    def __init__(self, server_url: str, username: str, password: str, 
                 batch_size: int = 1000, max_retries: int = 3):
        """
        Initialize the Cybereason Hash Collector.
        
        Args:
            server_url: Cybereason server URL
            username: Username for authentication
            password: Password for authentication
            batch_size: Number of records to process per batch
            max_retries: Maximum number of retry attempts for failed requests
        """
        self.server_url = server_url.rstrip('/')
        self.username = username
        self.password = password
        self.batch_size = batch_size
        self.max_retries = max_retries
        
        # Setup session with retry strategy
        self.session = requests.Session()
        self._setup_session()
        
        # Setup logging
        self._setup_logging()
        
        # Statistics tracking
        self.stats = {
            'total_hashes': 0,
            'unique_hashes': 0,
            'batches_processed': 0,
            'start_time': None,
            'errors': 0
        }
    
    def _setup_session(self) -> None:
        """Configure the requests session with retry strategy and SSL settings."""
        # Disable SSL verification for testing (enable in production)
        self.session.verify = False
        
        # Suppress SSL warnings
        import urllib3
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        
        # Setup retry strategy
        retry_strategy = Retry(
            total=self.max_retries,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["HEAD", "GET", "POST"]
        )
        
        adapter = HTTPAdapter(max_retries=retry_strategy)
        self.session.mount("http://", adapter)
        self.session.mount("https://", adapter)
        
        # Set default headers
        self.session.headers.update({
            'User-Agent': 'Cybereason-Hash-Collector/2.0.0',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive'
        })
    
    def _setup_logging(self) -> None:
        """Configure logging for the application."""
        log_format = '%(asctime)s - %(levelname)s - %(message)s'
        logging.basicConfig(
            level=logging.INFO,
            format=log_format,
            handlers=[
                logging.FileHandler('cybereason_hash_collector.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def authenticate(self) -> bool:
        """
        Authenticate with the Cybereason server.
        
        Returns:
            True if authentication successful, False otherwise
        """
        try:
            self.logger.info("Authenticating with Cybereason server...")
            
            # Test server accessibility
            if not self._test_server_accessibility():
                return False
            
            # Attempt login authentication
            if self._perform_login():
                self.logger.info("Authentication successful")
                return True
            else:
                self.logger.error("Authentication failed")
                return False
                
        except Exception as e:
            self.logger.error(f"Authentication error: {str(e)}")
            return False
    
    def _test_server_accessibility(self) -> bool:
        """Test if the server is accessible."""
        try:
            response = self.session.get(f"{self.server_url}/", timeout=30)
            self.logger.info(f"Server accessibility test: {response.status_code}")
            return response.status_code in [200, 401, 403]  # Any response means server is up
        except Exception as e:
            self.logger.error(f"Server accessibility test failed: {str(e)}")
            return False
    
    def _perform_login(self) -> bool:
        """
        Perform login authentication using the working method.
        
        Returns:
            True if login successful, False otherwise
        """
        try:
            login_url = f"{self.server_url}/login.html"
            
            # First, get the login page to establish session
            response = self.session.get(login_url, timeout=30)
            if response.status_code != 200:
                self.logger.error(f"Failed to get login page: {response.status_code}")
                return False
            
            # POST credentials
            auth_data = {
                'username': self.username,
                'password': self.password
            }
            
            auth_response = self.session.post(
                login_url,
                data=auth_data,
                headers={'Content-Type': 'application/x-www-form-urlencoded'},
                allow_redirects=True,
                timeout=30
            )
            
            # Check for successful authentication
            if self._is_authentication_successful(auth_response):
                self.logger.info("Login authentication successful")
                return True
            else:
                self.logger.warning("Login authentication failed")
                return False
                
        except Exception as e:
            self.logger.error(f"Login error: {str(e)}")
            return False
    
    def _is_authentication_successful(self, response) -> bool:
        """Check if authentication was successful based on response."""
        # Check for redirect to dashboard
        if 'dashboard' in response.url.lower() or 'main' in response.url.lower():
            return True
        
        # Check for dashboard content
        if ('dashboard' in response.text.lower() or 
            'main' in response.text.lower() or
            'app></app>' in response.text or
            len(response.text) > 2000):
            return True
        
        return False
    
    def collect_hashes(self, max_hashes: Optional[int] = None, 
                      output_file: Optional[str] = None) -> str:
        """
        Collect all unique hashes from Cybereason platform.
        
        Args:
            max_hashes: Maximum number of hashes to collect (None for unlimited)
            output_file: Output CSV file path (auto-generated if None)
            
        Returns:
            Path to the output CSV file
        """
        self.stats['start_time'] = time.time()
        self.logger.info("Starting hash collection process...")
        
        # Generate output filename if not provided
        if not output_file:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_file = f"cybereason_hashes_{timestamp}.csv"
        
        # Collect hashes using the most efficient method
        all_hashes = self._collect_hashes_efficiently(max_hashes)
        
        # Update statistics with actual hash count
        self.stats['unique_hashes'] = len(all_hashes)
        
        # Save to CSV
        self._save_hashes_to_csv(all_hashes, output_file)
        
        # Log completion statistics
        self._log_completion_stats()
        
        return output_file
    
    def _collect_hashes_efficiently(self, max_hashes: Optional[int] = None) -> Set[str]:
        """
        Collect hashes using the most efficient method available.
        
        Args:
            max_hashes: Maximum number of hashes to collect
            
        Returns:
            Set of unique hashes
        """
        all_hashes = set()
        
        # Primary method: Direct FileHash query (most efficient)
        self.logger.info("Using direct FileHash query method (most efficient)...")
        file_hashes = self._get_file_hashes_direct(max_hashes)
        all_hashes.update(file_hashes)
        
        self.logger.info(f"Collected {len(file_hashes)} hashes from FileHash entities")
        
        # If we need more hashes and haven't hit the limit, try additional sources
        if max_hashes is None or len(all_hashes) < max_hashes:
            remaining_limit = max_hashes - len(all_hashes) if max_hashes else None
            
            # Secondary method: Malops (if we have few hashes)
            if len(all_hashes) < 1000:
                self.logger.info("Collecting additional hashes from Malops...")
                malop_hashes = self._get_file_hashes_from_malops(remaining_limit)
                all_hashes.update(malop_hashes)
                self.logger.info(f"Added {len(malop_hashes)} hashes from Malops")
        
        return all_hashes
    
    def _get_file_hashes_direct(self, limit: Optional[int] = None) -> Set[str]:
        """
        Retrieve file hashes directly from FileHash entities (most efficient method).
        
        Args:
            limit: Maximum number of hashes to retrieve
            
        Returns:
            Set of unique file hashes
        """
        hashes = set()
        skip = 0
        batch_limit = self.batch_size
        max_batches = 10000  # Safety limit to prevent infinite loops (increased for large datasets)
        
        while True:
            try:
                query_url = f"{self.server_url}/rest/visualsearch/query/simple"
                
                # Calculate how many hashes we still need
                remaining_needed = limit - len(hashes) if limit else None
                current_batch_size = min(batch_limit, remaining_needed) if remaining_needed else batch_limit
                
                query = {
                    "queryPath": [
                        {
                            "requestedType": "FileHash",
                            "filters": [],
                            "isResult": True
                        }
                    ],
                    "totalResultLimit": current_batch_size,
                    "perGroupLimit": 100,
                    "perFeatureLimit": 100,
                    "templateContext": "SPECIFIC",
                    "queryTimeout": 120000,
                    "pagination": {
                        "pageSize": current_batch_size,
                        "skip": skip
                    },
                    "customFields": [
                        "elementDisplayName",
                        "sha1HexString",
                        "iconMd5HexString",
                        "maliciousClassificationType"
                    ]
                }
                
                batch_number = skip // batch_limit + 1
                self.logger.info(f"Fetching FileHash batch {batch_number} (skip: {skip}, batch_size: {current_batch_size})...")
                
                headers = {
                    'Content-Type': 'application/json;charset=UTF-8',
                    'Accept': 'application/json, text/plain, */*',
                    'query-strategy': 'investigation'
                }
                
                response = self.session.post(query_url, json=query, headers=headers, timeout=120)
                
                if response.status_code == 200:
                    data = response.json()
                    file_hashes = data.get('data', {}).get('resultIdToElementDataMap', {})
                    
                    if not file_hashes:
                        self.logger.info("No more FileHash entities found")
                        break
                    
                    # Check if we're getting the same data (pagination issue)
                    initial_hash_count = len(hashes)
                    batch_hashes = self._extract_hashes_from_batch(file_hashes)
                    hashes.update(batch_hashes)
                    new_hash_count = len(hashes)
                    actually_new_hashes = new_hash_count - initial_hash_count
                    
                    # If we didn't get any new hashes, we've reached the end
                    if actually_new_hashes == 0:
                        self.logger.info("No new hashes found - reached end of available data")
                        break
                    
                    # Calculate progress percentage if we have a limit
                    progress_info = ""
                    if limit:
                        progress = (len(hashes) / limit) * 100
                        progress_info = f" ({progress:.1f}% of target)"
                    
                    self.logger.info(f"Retrieved {actually_new_hashes} new hashes from batch (total: {len(hashes)}){progress_info}")
                    
                    # Check if we've hit our limit
                    if limit and len(hashes) >= limit:
                        # Trim to exact limit if we exceeded it
                        hashes = set(list(hashes)[:limit])
                        self.logger.info(f"Reached target limit of {limit} hashes")
                        break
                    
                    # Check if we got fewer results than requested (end of data)
                    if len(file_hashes) < current_batch_size:
                        self.logger.info("Reached end of FileHash data")
                        break
                    
                    skip += current_batch_size
                    self.stats['batches_processed'] += 1
                    
                    # Safety check to prevent infinite loops
                    if self.stats['batches_processed'] >= max_batches:
                        self.logger.warning(f"Reached maximum batch limit of {max_batches}, stopping collection")
                        break
                    
                else:
                    self.logger.error(f"Failed to fetch FileHash data: {response.status_code}")
                    self.stats['errors'] += 1
                    break
                    
            except requests.exceptions.RequestException as e:
                self.logger.error(f"Error fetching FileHash data: {str(e)}")
                self.stats['errors'] += 1
                
                # For connection errors, try to continue with next batch
                if "Connection broken" in str(e) or "IncompleteRead" in str(e):
                    self.logger.warning("Connection error detected, attempting to continue...")
                    skip += batch_limit
                    self.stats['batches_processed'] += 1
                    continue
                else:
                    break
        
        return hashes
    
    def _extract_hashes_from_batch(self, file_hashes: Dict) -> Set[str]:
        """
        Extract hashes from a batch of FileHash entities.
        
        Args:
            file_hashes: Dictionary of FileHash entities
            
        Returns:
            Set of extracted hashes
        """
        hashes = set()
        
        for hash_id, hash_data in file_hashes.items():
            simple_values = hash_data.get('simpleValues', {})
            
            # Extract SHA1 hashes
            if 'sha1HexString' in simple_values:
                sha1_data = simple_values['sha1HexString']
                if 'values' in sha1_data and sha1_data['values']:
                    for sha1_value in sha1_data['values']:
                        if self._is_valid_hash(sha1_value, 40):
                            hashes.add(sha1_value)
            
            # Extract MD5 hashes
            if 'iconMd5HexString' in simple_values:
                md5_data = simple_values['iconMd5HexString']
                if 'values' in md5_data and md5_data['values']:
                    for md5_value in md5_data['values']:
                        if self._is_valid_hash(md5_value, 32):
                            hashes.add(md5_value)
        
        return hashes
    
    def _is_valid_hash(self, hash_value: str, expected_length: int) -> bool:
        """
        Validate if a string is a valid hash.
        
        Args:
            hash_value: Hash string to validate
            expected_length: Expected length of the hash
            
        Returns:
            True if valid hash, False otherwise
        """
        return (hash_value and 
                isinstance(hash_value, str) and 
                len(hash_value) == expected_length and
                hash_value.isalnum())
    
    def _get_file_hashes_from_malops(self, limit: Optional[int] = None) -> Set[str]:
        """
        Retrieve file hashes from Malops (fallback method).
        
        Args:
            limit: Maximum number of hashes to retrieve
            
        Returns:
            Set of unique file hashes
        """
        hashes = set()
        
        try:
            query_url = f"{self.server_url}/rest/malops/query"
            
            query = {
                "queryPath": [
                    {
                        "requestedType": "MalopProcess",
                        "filters": [],
                        "isResult": True
                    }
                ],
                "totalResultLimit": min(limit or 1000, 1000),
                "perGroupLimit": 100,
                "perFeatureLimit": 100,
                "templateContext": "SPECIFIC",
                "queryTimeout": 120000,
                "customFields": [
                    "elementDisplayName",
                    "imageFile.md5String",
                    "imageFile.sha1String",
                    "imageFile.sha256String"
                ]
            }
            
            self.logger.info("Fetching hashes from Malops...")
            
            headers = {
                'Content-Type': 'application/json;charset=UTF-8',
                'Accept': 'application/json, text/plain, */*',
                'query-strategy': 'investigation'
            }
            
            response = self.session.post(query_url, json=query, headers=headers, timeout=120)
            
            if response.status_code == 200:
                data = response.json()
                malop_processes = data.get('data', {}).get('resultIdToElementDataMap', {})
                
                for process_id, process_data in malop_processes.items():
                    simple_values = process_data.get('simpleValues', {})
                    
                    # Extract hashes from imageFile fields
                    for hash_field in ['imageFile.md5String', 'imageFile.sha1String', 'imageFile.sha256String']:
                        if hash_field in simple_values:
                            hash_data = simple_values[hash_field]
                            if 'values' in hash_data and hash_data['values']:
                                for hash_value in hash_data['values']:
                                    if hash_value and isinstance(hash_value, str):
                                        hashes.add(hash_value)
                
                self.logger.info(f"Retrieved {len(hashes)} hashes from Malops")
            else:
                self.logger.error(f"Failed to fetch Malop data: {response.status_code}")
                self.stats['errors'] += 1
                
        except requests.exceptions.RequestException as e:
            self.logger.error(f"Error fetching Malop data: {str(e)}")
            self.stats['errors'] += 1
        
        return hashes
    
    def _save_hashes_to_csv(self, hashes: Set[str], output_file: str) -> None:
        """
        Save hashes to CSV file with proper formatting.
        
        Args:
            hashes: Set of unique hashes
            output_file: Output CSV file path
        """
        try:
            self.logger.info(f"Saving {len(hashes)} unique hashes to {output_file}...")
            
            with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
                writer = csv.writer(csvfile)
                
                # Write header
                writer.writerow(['Hash', 'Hash_Type', 'Collection_Date'])
                
                # Write hash data
                collection_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                
                for hash_value in sorted(hashes):
                    # Determine hash type based on length
                    if len(hash_value) == 32:
                        hash_type = "MD5"
                    elif len(hash_value) == 40:
                        hash_type = "SHA1"
                    elif len(hash_value) == 64:
                        hash_type = "SHA256"
                    else:
                        hash_type = "UNKNOWN"
                    
                    writer.writerow([hash_value, hash_type, collection_date])
            
            self.logger.info(f"Successfully saved {len(hashes)} unique hashes to {output_file}")
            
        except Exception as e:
            self.logger.error(f"Error saving hashes to CSV: {str(e)}")
            raise
    
    def _log_completion_stats(self) -> None:
        """Log completion statistics."""
        if self.stats['start_time']:
            duration = time.time() - self.stats['start_time']
            self.logger.info("=" * 50)
            self.logger.info("COLLECTION COMPLETED")
            self.logger.info("=" * 50)
            self.logger.info(f"Total unique hashes: {self.stats['unique_hashes']}")
            self.logger.info(f"Batches processed: {self.stats['batches_processed']}")
            self.logger.info(f"Errors encountered: {self.stats['errors']}")
            self.logger.info(f"Duration: {duration:.2f} seconds")
            if duration > 0:
                self.logger.info(f"Average rate: {self.stats['unique_hashes']/duration:.2f} hashes/second")
            self.logger.info("=" * 50)


def main():
    """Main function to run the Cybereason Hash Collector."""
    parser = argparse.ArgumentParser(
        description="Professional Cybereason Hash Collector",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic usage with default settings
  python cybereason_hash_collector.py
  
  # Collect specific number of hashes
  python cybereason_hash_collector.py --max-hashes 10000
  
  # Use custom server and credentials
  python cybereason_hash_collector.py --server https://your-server.com --username user --password pass
  
  # Large dataset collection with custom batch size
  python cybereason_hash_collector.py --max-hashes 8000000 --batch-size 5000
  
  # Test connection only
  python cybereason_hash_collector.py --test-only
        """
    )
    
    parser.add_argument('--server', default=CYBEREASON_SERVER,
                       help='Cybereason server URL')
    parser.add_argument('--username', default=CYBEREASON_USERNAME,
                       help='Username for authentication')
    parser.add_argument('--password', default=CYBEREASON_PASSWORD,
                       help='Password for authentication')
    parser.add_argument('--max-hashes', type=int, default=8000000,
                       help='Maximum number of hashes to collect (default: 8000000)')
    parser.add_argument('--batch-size', type=int, default=10000,
                       help='Batch size for processing (default: 10000)')
    parser.add_argument('--output', type=str, default=None,
                       help='Output CSV file path (auto-generated if not specified)')
    parser.add_argument('--test-only', action='store_true',
                       help='Test connection only, do not collect hashes')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Enable verbose logging')
    
    args = parser.parse_args()
    
    # Set logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        # Initialize collector
        collector = CybereasonHashCollector(
            server_url=args.server,
            username=args.username,
            password=args.password,
            batch_size=args.batch_size
        )
        
        # Test authentication
        if not collector.authenticate():
            print("❌ Authentication failed. Please check your credentials and server URL.")
            sys.exit(1)
        
        if args.test_only:
            print("✅ Connection test successful!")
            return
        
        # Collect hashes
        output_file = collector.collect_hashes(
            max_hashes=args.max_hashes,
            output_file=args.output
        )
        
        print(f"✅ Success! Hashes saved to: {output_file}")
        
    except KeyboardInterrupt:
        print("\n⚠️  Collection interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Script failed: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
