import React, { useState, useEffect } from 'react';
import type { StockItem } from '../../services/stockService';
import { stockService, MASTER_MEDICINES, calculateStatus } from '../../services/stockService';
import './Stock.css';

export const Stock: React.FC = () => {
  // --- State Variables ---
  const [stockItems, setStockItems] = useState<StockItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);

  // Filter States
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [selectedStatus, setSelectedStatus] = useState<string>('');

  // Pagination States
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [itemsPerPage] = useState<number>(5);

  // Modal Control States
  const [activeModal, setActiveModal] = useState<'add' | 'edit' | 'delete' | 'details' | null>(null);
  const [selectedItem, setSelectedItem] = useState<StockItem | null>(null);

  // Add / Edit Form States
  const [medSearchInput, setMedSearchInput] = useState<string>('');
  const [isDropdownOpen, setIsDropdownOpen] = useState<boolean>(false);
  const [formCategory, setFormCategory] = useState<string>('');
  const [formStrength, setFormStrength] = useState<string>('');
  const [formQuantity, setFormQuantity] = useState<number>(0);
  const [formMinLevel, setFormMinLevel] = useState<number>(0);
  const [formErrors, setFormErrors] = useState<{ [key: string]: string }>({});

  // --- Load Initial Data ---
  const loadStockData = async () => {
    setLoading(true);
    try {
      const items = await stockService.getStock();
      setStockItems(items);
    } catch (err) {
      console.error('Failed to load stock data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadStockData();
  }, []);

  // --- Refresh Trigger ---
  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      const items = await stockService.getStock();
      setStockItems(items);
      setCurrentPage(1);
    } catch (err) {
      console.error('Failed to refresh stock:', err);
    } finally {
      setRefreshing(false);
    }
  };

  // --- Dynamic Summary Metrics ---
  const totalMedicines = stockItems.length;
  const inStockCount = stockItems.filter(item => item.currentStock > 0).length;
  const lowStockCount = stockItems.filter(item => item.status === 'Low Stock' || item.status === 'Critical').length;
  const outOfStockCount = stockItems.filter(item => item.currentStock === 0).length;

  // Unique categories list for the filter dropdown
  const categoriesList = Array.from(new Set(stockItems.map(item => item.category)));

  // --- Filter Logic ---
  const handleFilterChange = (type: 'search' | 'category' | 'status', value: string) => {
    if (type === 'search') setSearchQuery(value);
    if (type === 'category') setSelectedCategory(value);
    if (type === 'status') setSelectedStatus(value);
    setCurrentPage(1); // Reset page on filter update
  };

  const handleClearFilters = () => {
    setSearchQuery('');
    setSelectedCategory('');
    setSelectedStatus('');
    setCurrentPage(1);
  };

  const filteredItems = stockItems.filter(item => {
    const matchesSearch = item.medicineName.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          item.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          item.strength.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory ? item.category === selectedCategory : true;
    const matchesStatus = selectedStatus ? item.status === selectedStatus : true;
    return matchesSearch && matchesCategory && matchesStatus;
  });

  // --- Pagination Slice ---
  const totalItemsCount = filteredItems.length;
  const totalPages = Math.ceil(totalItemsCount / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = Math.min(startIndex + itemsPerPage, totalItemsCount);
  const paginatedItems = filteredItems.slice(startIndex, endIndex);

  // --- Autocomplete Searchable Selector Filter ---
  const autocompleteSuggestions = MASTER_MEDICINES.filter(med =>
    med.name.toLowerCase().includes(medSearchInput.toLowerCase())
  );

  const handleSelectSuggestion = (med: { name: string; category: string; strength: string }) => {
    setMedSearchInput(med.name);
    setFormCategory(med.category);
    setFormStrength(med.strength);
    setIsDropdownOpen(false);
    if (formErrors.medicineName) setFormErrors(prev => ({ ...prev, medicineName: '' }));
    if (formErrors.category) setFormErrors(prev => ({ ...prev, category: '' }));
    if (formErrors.strength) setFormErrors(prev => ({ ...prev, strength: '' }));
  };

  // --- Modal Forms Triggers ---
  const openAddModal = () => {
    setMedSearchInput('');
    setFormCategory('');
    setFormStrength('');
    setFormQuantity(0);
    setFormMinLevel(0);
    setFormErrors({});
    setIsDropdownOpen(false);
    setSelectedItem(null);
    setActiveModal('add');
  };

  const openEditModal = (item: StockItem) => {
    setMedSearchInput(item.medicineName);
    setFormCategory(item.category);
    setFormStrength(item.strength);
    setFormQuantity(item.currentStock);
    setFormMinLevel(item.minStockLevel);
    setFormErrors({});
    setIsDropdownOpen(false);
    setSelectedItem(item);
    setActiveModal('edit');
  };

  const openDeleteConfirm = (item: StockItem) => {
    setSelectedItem(item);
    setActiveModal('delete');
  };

  const openDetailsModal = (item: StockItem) => {
    setSelectedItem(item);
    setActiveModal('details');
  };

  const closeModal = () => {
    setActiveModal(null);
    setSelectedItem(null);
  };

  // --- Form Validation ---
  const validateForm = () => {
    const errors: { [key: string]: string } = {};
    if (!medSearchInput.trim()) errors.medicineName = 'Medicine name is required.';
    if (!formCategory.trim()) errors.category = 'Category is required.';
    if (!formStrength.trim()) errors.strength = 'Strength details are required.';
    if (formQuantity < 0) errors.quantity = 'Stock quantity cannot be negative.';
    if (formMinLevel <= 0) errors.minLevel = 'Minimum stock level must be positive.';
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // --- Stateful CRUD Submissions ---
  const handleAddSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    const newItem: StockItem = {
      id: `STK-${Math.floor(100 + Math.random() * 900)}`,
      medicineName: medSearchInput.trim(),
      category: formCategory.trim(),
      strength: formStrength.trim(),
      currentStock: formQuantity,
      minStockLevel: formMinLevel,
      status: calculateStatus(formQuantity, formMinLevel),
      lastUpdated: 'Just now'
    };

    setStockItems(prev => [newItem, ...prev]);
    closeModal();
  };

  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm() || !selectedItem) return;

    setStockItems(prev =>
      prev.map(item =>
        item.id === selectedItem.id
          ? {
              ...item,
              medicineName: medSearchInput.trim(),
              category: formCategory.trim(),
              strength: formStrength.trim(),
              currentStock: formQuantity,
              minStockLevel: formMinLevel,
              status: calculateStatus(formQuantity, formMinLevel),
              lastUpdated: 'Just now'
            }
          : item
      )
    );
    closeModal();
  };

  const handleDeleteSubmit = () => {
    if (!selectedItem) return;
    setStockItems(prev => prev.filter(item => item.id !== selectedItem.id));
    closeModal();
  };

  // Render Loader Skeleton
  if (loading) {
    return (
      <div className="stock-page">
        <div className="skeleton-box skeleton-header" />
        <div className="skeleton-grid">
          <div className="skeleton-box skeleton-card" />
          <div className="skeleton-box skeleton-card" />
          <div className="skeleton-box skeleton-card" />
          <div className="skeleton-box skeleton-card" />
        </div>
        <div className="skeleton-box skeleton-main" />
      </div>
    );
  }

  return (
    <div className="stock-page">
      {/* Top Header */}
      <header className="stock-header">
        <div>
          <h1 className="stock-title">Stock Management</h1>
          <p className="stock-subtitle">Monitor, restock, and manage your medicine inventory levels.</p>
        </div>
        <div className="header-actions">
          <button onClick={handleRefresh} className="btn btn-secondary" disabled={refreshing}>
            <svg className={`icon-btn-svg ${refreshing ? 'spinner' : ''}`} viewBox="0 0 24 24">
              <path d="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z" />
            </svg>
            <span>{refreshing ? 'Refreshing...' : 'Refresh'}</span>
          </button>
          <button onClick={openAddModal} className="btn btn-primary">
            <svg className="icon-btn-svg" viewBox="0 0 24 24">
              <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z" />
            </svg>
            <span>Add Stock</span>
          </button>
        </div>
      </header>

      {/* KPI summary Row */}
      <div className="kpi-grid">
        {/* Total Medicines */}
        <div className="kpi-card kpi-total">
          <div className="kpi-info">
            <span className="kpi-title">Total Medicines</span>
            <span className="kpi-value">{totalMedicines}</span>
            <span className="kpi-supporting">In inventory</span>
          </div>
          <div className="kpi-icon-wrapper">
            <svg className="kpi-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
          </div>
        </div>

        {/* In Stock */}
        <div className="kpi-card kpi-instock">
          <div className="kpi-info">
            <span className="kpi-title">In Stock</span>
            <span className="kpi-value">{inStockCount}</span>
            <span className="kpi-supporting">Available for dispatch</span>
          </div>
          <div className="kpi-icon-wrapper">
            <svg className="kpi-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>

        {/* Low Stock */}
        <div className="kpi-card kpi-lowstock">
          <div className="kpi-info">
            <span className="kpi-title">Low Stock</span>
            <span className="kpi-value">{lowStockCount}</span>
            <span className="kpi-supporting">Needs restocking</span>
          </div>
          <div className="kpi-icon-wrapper">
            <svg className="kpi-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
        </div>

        {/* Out of Stock */}
        <div className="kpi-card kpi-outstock">
          <div className="kpi-info">
            <span className="kpi-title">Out of Stock</span>
            <span className="kpi-value">{outOfStockCount}</span>
            <span className="kpi-supporting">Critical shortage</span>
          </div>
          <div className="kpi-icon-wrapper">
            <svg className="kpi-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
      </div>

      {/* Filter and search controls panel */}
      <div className="filters-container">
        {/* Search */}
        <div className="filter-group">
          <label className="filter-label" htmlFor="med-search">Search Medicine</label>
          <input
            id="med-search"
            type="text"
            className="filter-input"
            placeholder="Search by name, strength, category..."
            value={searchQuery}
            onChange={(e) => handleFilterChange('search', e.target.value)}
          />
        </div>

        {/* Category Filter */}
        <div className="filter-group">
          <label className="filter-label" htmlFor="cat-filter">Category</label>
          <select
            id="cat-filter"
            className="filter-select"
            value={selectedCategory}
            onChange={(e) => handleFilterChange('category', e.target.value)}
          >
            <option value="">All Categories</option>
            {categoriesList.map(cat => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
          </select>
        </div>

        {/* Status Filter */}
        <div className="filter-group">
          <label className="filter-label" htmlFor="stat-filter">Status</label>
          <select
            id="stat-filter"
            className="filter-select"
            value={selectedStatus}
            onChange={(e) => handleFilterChange('status', e.target.value)}
          >
            <option value="">All Statuses</option>
            <option value="Available">Available</option>
            <option value="Low Stock">Low Stock</option>
            <option value="Critical">Critical</option>
            <option value="Out of Stock">Out of Stock</option>
          </select>
        </div>

        {/* Clear Filters Action */}
        {(searchQuery || selectedCategory || selectedStatus) && (
          <button onClick={handleClearFilters} className="btn-clear">
            Clear Filters
          </button>
        )}
      </div>

      {/* Table grid area */}
      <div className="table-card">
        <div className="table-responsive">
          <table className="stock-table">
            <thead>
              <tr>
                <th>Medicine</th>
                <th>Category</th>
                <th>Strength</th>
                <th>Current Stock</th>
                <th>Stock Level</th>
                <th>Status</th>
                <th>Last Updated</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {paginatedItems.length > 0 ? (
                paginatedItems.map((item) => {
                  const percent = Math.min(Math.round((item.currentStock / (item.minStockLevel * 2)) * 100), 100);
                  let fillClass = 'level-high';
                  if (item.status === 'Low Stock') fillClass = 'level-low';
                  if (item.status === 'Critical' || item.status === 'Out of Stock') fillClass = 'level-critical';



                  return (
                    <tr key={item.id}>
                      <td style={{ fontWeight: 600, color: '#0f172a' }}>{item.medicineName}</td>
                      <td>{item.category}</td>
                      <td>{item.strength}</td>
                      <td>{item.currentStock} units</td>
                      <td>
                        <div className="stock-level-wrapper">
                          <div className="stock-level-bar">
                            <div className={`stock-level-fill ${fillClass}`} style={{ width: `${percent}%` }} />
                          </div>
                          <span className="stock-level-text">{percent}% of safety target</span>
                        </div>
                      </td>
                      <td>
                        {/* Render customized table status badges */}
                        <span className={`badge ${
                          item.status === 'Available' ? 'badge-low' : 
                          item.status === 'Low Stock' ? 'badge-low' : 
                          'badge-critical'
                        }`} style={{
                          backgroundColor: 
                            item.status === 'Available' ? '#ecfdf5' : 
                            item.status === 'Low Stock' ? '#fffbeb' : 
                            '#fef2f2',
                          color: 
                            item.status === 'Available' ? '#047857' : 
                            item.status === 'Low Stock' ? '#b45309' : 
                            '#b91c1c'
                        }}>
                          {item.status}
                        </span>
                      </td>
                      <td style={{ fontSize: '13px', color: '#64748b' }}>{item.lastUpdated}</td>
                      <td style={{ textAlign: 'right' }}>
                        <div className="action-buttons" style={{ justifyContent: 'flex-end' }}>
                          {/* View details */}
                          <button onClick={() => openDetailsModal(item)} className="btn-icon-only" title="View Details">
                            <svg className="btn-icon-only-svg" viewBox="0 0 24 24">
                              <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z" />
                            </svg>
                          </button>
                          {/* Edit */}
                          <button onClick={() => openEditModal(item)} className="btn-icon-only edit-action" title="Edit">
                            <svg className="btn-icon-only-svg" viewBox="0 0 24 24">
                              <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" />
                            </svg>
                          </button>
                          {/* Delete */}
                          <button onClick={() => openDeleteConfirm(item)} className="btn-icon-only delete-action" title="Delete">
                            <svg className="btn-icon-only-svg" viewBox="0 0 24 24">
                              <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" />
                            </svg>
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', padding: '40px', color: '#94a3b8' }}>
                    No medicines found matching the active filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination bar */}
        {totalItemsCount > 0 && (
          <div className="pagination-container">
            <span className="pagination-info">
              Showing <strong>{startIndex + 1}</strong> to <strong>{endIndex}</strong> of <strong>{totalItemsCount}</strong> medicines
            </span>
            <div className="pagination-controls">
              <button
                className="page-btn"
                onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                disabled={currentPage === 1}
              >
                Previous
              </button>
              {Array.from({ length: totalPages }, (_, idx) => (
                <button
                  key={idx + 1}
                  className={`page-btn ${currentPage === idx + 1 ? 'active' : ''}`}
                  onClick={() => setCurrentPage(idx + 1)}
                >
                  {idx + 1}
                </button>
              ))}
              <button
                className="page-btn"
                onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                disabled={currentPage === totalPages}
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>

      {/* --- ADD / EDIT STOCK MODAL --- */}
      {(activeModal === 'add' || activeModal === 'edit') && (
        <div className="modal-backdrop" onClick={closeModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title">
                {activeModal === 'add' ? 'Add Inventory Stock' : 'Edit Stock Item'}
              </h3>
              <button onClick={closeModal} className="modal-close-btn">&times;</button>
            </div>
            <form onSubmit={activeModal === 'add' ? handleAddSubmit : handleEditSubmit}>
              <div className="modal-body">
                {/* Searchable Medicine Dropdown */}
                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label className="form-label-desc" htmlFor="autocomplete-input">Medicine Name</label>
                  <div className="autocomplete-container">
                    <input
                      id="autocomplete-input"
                      type="text"
                      className={`filter-input ${formErrors.medicineName ? 'has-error' : ''}`}
                      placeholder="Type to search standard medicine list..."
                      value={medSearchInput}
                      onChange={(e) => {
                        setMedSearchInput(e.target.value);
                        setIsDropdownOpen(true);
                      }}
                      onFocus={() => setIsDropdownOpen(true)}
                      disabled={activeModal === 'edit'} // Lock name editing in edit mode to represent static reference
                    />
                    {isDropdownOpen && medSearchInput.trim() !== '' && activeModal === 'add' && (
                      <div className="autocomplete-results">
                        {autocompleteSuggestions.length > 0 ? (
                          autocompleteSuggestions.map((med) => (
                            <div
                              key={med.name}
                              className="autocomplete-item"
                              onClick={() => handleSelectSuggestion(med)}
                            >
                              <span>{med.name}</span>
                              <span className="autocomplete-meta">{med.strength} · {med.category}</span>
                            </div>
                          ))
                        ) : (
                          <div className="autocomplete-empty">
                            No match found. Free typing mode active.
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                  {formErrors.medicineName && (
                    <span className="field-error" style={{ color: '#de3545', fontSize: '12px' }}>
                      {formErrors.medicineName}
                    </span>
                  )}
                </div>

                {/* Category & Strength Row */}
                <div className="form-row">
                  <div className="form-group">
                    <label className="form-label-desc" htmlFor="form-cat">Category</label>
                    <input
                      id="form-cat"
                      type="text"
                      className="filter-input"
                      placeholder="e.g. Antibiotic"
                      value={formCategory}
                      onChange={(e) => setFormCategory(e.target.value)}
                      disabled={activeModal === 'edit'}
                    />
                    {formErrors.category && (
                      <span className="field-error" style={{ color: '#de3545', fontSize: '12px' }}>{formErrors.category}</span>
                    )}
                  </div>
                  <div className="form-group">
                    <label className="form-label-desc" htmlFor="form-strength">Strength</label>
                    <input
                      id="form-strength"
                      type="text"
                      className="filter-input"
                      placeholder="e.g. 500mg"
                      value={formStrength}
                      onChange={(e) => setFormStrength(e.target.value)}
                      disabled={activeModal === 'edit'}
                    />
                    {formErrors.strength && (
                      <span className="field-error" style={{ color: '#de3545', fontSize: '12px' }}>{formErrors.strength}</span>
                    )}
                  </div>
                </div>

                {/* Quantity & Min Stock Target Row */}
                <div className="form-row">
                  <div className="form-group">
                    <label className="form-label-desc" htmlFor="form-qty">Current Stock (Units)</label>
                    <input
                      id="form-qty"
                      type="number"
                      className="filter-input"
                      placeholder="0"
                      value={formQuantity}
                      onChange={(e) => setFormQuantity(parseInt(e.target.value) || 0)}
                    />
                    {formErrors.quantity && (
                      <span className="field-error" style={{ color: '#de3545', fontSize: '12px' }}>{formErrors.quantity}</span>
                    )}
                  </div>
                  <div className="form-group">
                    <label className="form-label-desc" htmlFor="form-min">Min Safety Level</label>
                    <input
                      id="form-min"
                      type="number"
                      className="filter-input"
                      placeholder="50"
                      value={formMinLevel}
                      onChange={(e) => setFormMinLevel(parseInt(e.target.value) || 0)}
                    />
                    {formErrors.minLevel && (
                      <span className="field-error" style={{ color: '#de3545', fontSize: '12px' }}>{formErrors.minLevel}</span>
                    )}
                  </div>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" onClick={closeModal} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  {activeModal === 'add' ? 'Add Medicine' : 'Save Changes'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* --- DETAILS MODAL --- */}
      {activeModal === 'details' && selectedItem && (
        <div className="modal-backdrop" onClick={closeModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title">Medicine Details</h3>
              <button onClick={closeModal} className="modal-close-btn">&times;</button>
            </div>
            <div className="modal-body">
              <div className="details-list">
                <div className="details-row">
                  <span className="details-label">ID Reference:</span>
                  <span className="details-value">{selectedItem.id}</span>
                </div>
                <div className="details-row">
                  <span className="details-label">Medicine:</span>
                  <span className="details-value">{selectedItem.medicineName}</span>
                </div>
                <div className="details-row">
                  <span className="details-label">Category:</span>
                  <span className="details-value">{selectedItem.category}</span>
                </div>
                <div className="details-row">
                  <span className="details-label">Strength:</span>
                  <span className="details-value">{selectedItem.strength}</span>
                </div>
                <div className="details-row">
                  <span className="details-label">Current Stock:</span>
                  <span className="details-value">{selectedItem.currentStock} units</span>
                </div>
                <div className="details-row">
                  <span className="details-label">Min Safety Level:</span>
                  <span className="details-value">{selectedItem.minStockLevel} units</span>
                </div>
                <div className="details-row">
                  <span className="details-label">Stock Status:</span>
                  <span className="details-value" style={{
                    color: 
                      selectedItem.status === 'Available' ? '#047857' : 
                      selectedItem.status === 'Low Stock' ? '#b45309' : 
                      '#b91c1c'
                  }}>{selectedItem.status}</span>
                </div>
                <div className="details-row">
                  <span className="details-label">Last Updated:</span>
                  <span className="details-value">{selectedItem.lastUpdated}</span>
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button onClick={closeModal} className="btn btn-secondary">
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* --- DELETE CONFIRM MODAL --- */}
      {activeModal === 'delete' && selectedItem && (
        <div className="modal-backdrop" onClick={closeModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title" style={{ color: '#b91c1c' }}>Confirm Deletion</h3>
              <button onClick={closeModal} className="modal-close-btn">&times;</button>
            </div>
            <div className="modal-body">
              <p className="delete-confirm-text">
                Are you sure you want to delete <span className="med-delete-highlight">{selectedItem.medicineName} ({selectedItem.strength})</span> from the pharmacy inventory?
              </p>
              <p style={{ fontSize: '12px', color: '#ef4444', marginTop: '12px', fontWeight: 'bold' }}>
                Warning: This action cannot be undone.
              </p>
            </div>
            <div className="modal-footer">
              <button onClick={closeModal} className="btn btn-secondary">
                Cancel
              </button>
              <button onClick={handleDeleteSubmit} className="btn btn-danger">
                Delete Stock
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Stock;
